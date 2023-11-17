import "regent"

-- Helper modules to handle PNG files and command line arguments
local png        = require("png_util")
local EdgeConfig = require("edge_config")
local coloring   = require("coloring_util")

-- Some C APIs
local c     = regentlib.c
local sqrt  = regentlib.sqrt(double)
local cmath = terralib.includec("math.h")
local PI = cmath.M_PI

-- 2D vector type
struct Vector2d
{
  x : double;
  y : double;
}

-- This code will be specialized for the CPU. If you want a CPU/GPU version, write it in Regent.
local cpu_sqrt = sqrt:get_definition()
terra Vector2d:norm()
  return cpu_sqrt(self.x * self.x + self.y * self.y)
end

terra Vector2d.metamethods.__div(v : Vector2d, c : double)
  return Vector2d { v.x / c, v.y / c }
end

-- Field space for pixels
fspace Pixel
{
  original      : uint8;    -- Original pixel in 8-bit gray scale
  smooth        : uint8;    -- Pixel after Gaussian smoothing
  gradient      : Vector2d; -- Gradient vector
  local_maximum : bool;     -- Marks if the gradient is a local maximum
  edge          : uint8;    -- Extracted edge
}

task factorize(parallelism : int) : int2d
  var limit = [int](cmath.sqrt([double](parallelism)))
  var size_x = 1
  var size_y = parallelism
  for i = 1, limit + 1 do
    if parallelism % i == 0 then
      size_x, size_y = i, parallelism / i
      if size_x > size_y then
        size_x, size_y = size_y, size_x
      end
    end
  end
  return int2d { size_x, size_y }
end

task create_interior_partition(r_image : region(ispace(int2d), Pixel))
  var coloring = c.legion_domain_coloring_create()
  var bounds = r_image.ispace.bounds
  c.legion_domain_coloring_color_domain(coloring, 0,
    rect2d { bounds.lo + {2, 2}, bounds.hi - {2, 2} })
  var interior_image_partition = partition(disjoint, r_image, coloring)
  c.legion_domain_coloring_destroy(coloring)
  return interior_image_partition
end

--
-- The 'initialize' task reads the image data from the file and initializes
-- the fields for later tasks. The upper left and lower right corners of the image
-- correspond to point {0, 0} and {width - 1, height - 1}, respectively.
--
task initialize(r_image : region(ispace(int2d), Pixel),
                filename : int8[256])
where
  reads writes(r_image)
do
  png.read_png_file(filename,
                    __physical(r_image.original),
                    __fields(r_image.original),
                    r_image.bounds)
  for e in r_image do
    r_image[e].smooth = r_image[e].original
    r_image[e].gradient = {0, 0}
    r_image[e].local_maximum = true
  end
  return 1
end

--
-- The 'smooth' task implements Gaussian smoothing, which is a convolution
-- between the image and the following 5x5 filter:
--
--        |  2  4  5  4  2 |
--   1    |  4  9 12  9  4 |
--  --- * |  5 12 15 12  5 |
--  159   |  4  9 12  9  4 |
--        |  2  4  5  4  2 |
--
-- Note that the upper left corner of the filter is applied to the
-- pixel that is off from the center by (-2, -2).
--
task smooth(r_image    : region(ispace(int2d), Pixel),
            r_interior : region(ispace(int2d), Pixel))
where
  reads(r_image.original), writes(r_interior.smooth)
do
  var ts_start = c.legion_get_current_time_in_micros()
  for e in r_interior do
    var smooth : double = 15 * r_image[e].original
    for polarity = 1, -2, -2 do
      smooth +=
        12.0 * r_image[e + {1 * polarity, 0 * polarity}].original +
         9.0 * r_image[e + {1 * polarity, 1 * polarity}].original +
         4.0 * r_image[e + {1 * polarity, 2 * polarity}].original +
         5.0 * r_image[e + {2 * polarity, 0 * polarity}].original +
         4.0 * r_image[e + {2 * polarity, 1 * polarity}].original +
         2.0 * r_image[e + {2 * polarity, 2 * polarity}].original

      smooth +=
        12.0 * r_image[e + {0 * polarity, 1 * -polarity}].original +
         9.0 * r_image[e + {1 * polarity, 1 * -polarity}].original +
         4.0 * r_image[e + {2 * polarity, 1 * -polarity}].original +
         5.0 * r_image[e + {0 * polarity, 2 * -polarity}].original +
         4.0 * r_image[e + {1 * polarity, 2 * -polarity}].original +
         2.0 * r_image[e + {2 * polarity, 2 * -polarity}].original
    end
    r_interior[e].smooth = [uint8](smooth / 159.0)
  end
  var ts_end = c.legion_get_current_time_in_micros()
  c.printf("Gaussian smoothing took %.3f sec.\n", (ts_end - ts_start) * 1e-6)
end

--
-- TODO: Copy and paste your 'sobelX', 'sobelY', and 'suppressNonmax' tasks here
--

--
-- Implement task 'sobelX'
--
-- The 'sobelX' task finds x component of the gradient vector at each pixel.
-- Use the following 3x3 filter to implement this task:
--
--  | -1  0  1 |
--  | -2  0  2 |
--  | -1  0  1 |
--
task sobelX(r_image    : region(ispace(int2d), Pixel),
            r_interior : region(ispace(int2d), Pixel))
-- Provide necessary privileges for this task
where
  reads(r_image.smooth), writes(r_interior.gradient.x)
do
  var ts_start = c.legion_get_current_time_in_micros()
  for e in r_interior do
    -- Fill the body of this loop
    var gradx : double = 0
    gradx +=
         2.0 * r_image[e + { 1,  0}].smooth +
         1.0 * r_image[e + { 1,  1}].smooth +
         1.0 * r_image[e + { 1, -1}].smooth +
        -2.0 * r_image[e + {-1,  0}].smooth +
        -1.0 * r_image[e + {-1,  1}].smooth +
        -1.0 * r_image[e + {-1, -1}].smooth

   r_interior[e].gradient.x = [double](gradx)

  end
  var ts_end = c.legion_get_current_time_in_micros()
  c.printf("Sobel operator on x-axis took %.3f sec.\n", (ts_end - ts_start) * 1e-6)
end

--
-- Implement task 'sobelY'
--
-- The 'sobelY' task finds y component of the gradient vector at each pixel.
-- Use the following 3x3 filter to implement this task:
--
--  | -1 -2 -1 |
--  |  0  0  0 |
--  |  1  2  1 |
--
task sobelY(r_image    : region(ispace(int2d), Pixel),
            r_interior : region(ispace(int2d), Pixel))
-- Provide necessary privileges for this task
where
  reads(r_image.smooth), writes(r_interior.gradient.y)
do
  var ts_start = c.legion_get_current_time_in_micros()
  for e in r_interior do
    -- Fill the body of this loop
    var grady : double = 0
    grady +=
        -2.0 * r_image[e + { 0,  1}].smooth +
         2.0 * r_image[e + { 0, -1}].smooth +
        -1.0 * r_image[e + { 1,  1}].smooth +
         1.0 * r_image[e + { 1, -1}].smooth +
        -1.0 * r_image[e + {-1,  1}].smooth +
         1.0 * r_image[e + {-1, -1}].smooth

   r_interior[e].gradient.y = [double](grady)
  end
  var ts_end = c.legion_get_current_time_in_micros()
  c.printf("Sobel operator on y-axis took %.3f sec.\n", (ts_end - ts_start) * 1e-6)
end

--
-- Implement task 'suppressNonmax'
--
-- The 'suppressNonmax' task filters only the gradients that are local maximum.
-- Each gradient is compared with two neighbors along its positive
-- and negative direction. The gradient direction is rounded to nearest 45°
-- to work on a discrete image. The following diagram will be useful to
-- determine which neighbors to pick for the comparison:
--
--           j - 1    j      j + 1    x-axis
--         -------------------------
--         |  45°  |  90°  |  135° |
--  i - 1  |  or   |  or   |  or   |
--         |  225° |  270° |  315° |
--         |------------------------
--         |  0°   |       |  0°   |
--    i    |  or   | center|  or   |
--         |  180° |       |  180° |
--         |------------------------
--         |  135° |  90°  |  45°  |
--  i + 1  |  or   |  or   |  or   |
--         |  315° |  270° |  225° |
--         -------------------------
--  y-axis
--
-- Hint: You might want to call some math functions with module 'cmath' imported
--       above.
--
task suppressNonmax(r_image    : region(ispace(int2d), Pixel),
                    r_interior : region(ispace(int2d), Pixel))
-- Provide necessary privileges for this task
where
  reads(r_image.gradient), writes(r_interior.local_maximum)
do
  var ts_start = c.legion_get_current_time_in_micros()
  for e in r_interior do
    -- Fill the body of this loop
    var local_maxi : bool = false
    var theta : double = cmath.atan2(r_image[e].gradient.y, r_image[e].gradient.x) * 180 / 3.1415926 + 180
    var direction : int32 = [int32](cmath.rint(theta / 45.0))
    -- this switch could be avoided.
    var switch_case : int32 = direction % 4
    if switch_case == 0 then
        var gradmax_0 = cmath.fmax(r_image[e + {-1, 0}].gradient:norm(), r_image[e + {1, 0}].gradient:norm())
        local_maxi = local_maxi or (r_image[e].gradient:norm() > gradmax_0)
    elseif switch_case == 1 then
        var gradmax_1 = cmath.fmax(r_image[e + {1, 1}].gradient:norm(), r_image[e + {-1, -1}].gradient:norm())
        local_maxi = local_maxi or (r_image[e].gradient:norm() > gradmax_1)
    elseif switch_case == 2 then
        var gradmax_2 = cmath.fmax(r_image[e + {0, 1}].gradient:norm(), r_image[e + {0, -1}].gradient:norm())
        local_maxi = local_maxi or (r_image[e].gradient:norm() > gradmax_2)
    elseif switch_case == 3 then
        var gradmax_3 = cmath.fmax(r_image[e + {-1, 1}].gradient:norm(), r_image[e + {1, -1}].gradient:norm())
        local_maxi = local_maxi or (r_image[e].gradient:norm() > gradmax_3)
    end
    r_interior[e].local_maximum = local_maxi
  end
  var ts_end = c.legion_get_current_time_in_micros()
  c.printf("Non-maximum suppression took %.3f sec.\n", (ts_end - ts_start) * 1e-6)
end


task edgeFromGradient(r_image : region(ispace(int2d), Pixel),
                      threshold : double)
where
  reads(r_image.{gradient, local_maximum}),
  writes(r_image.edge)
do
  for e in r_image do
    if e.local_maximum and e.gradient:norm() >= threshold then
      e.edge = 255
    end
  end
end

task saveEdge(r_image : region(ispace(int2d), Pixel),
              filename : int8[256])
where
  reads(r_image.edge)
do
  png.write_png_file(filename,
                     __physical(r_image.edge),
                     __fields(r_image.edge),
                     r_image.bounds)
end

task toplevel()
  var config : EdgeConfig
  config:initialize_from_command()

  -- Create a logical region for original image and intermediate results
  var size_image = png.get_image_size(config.filename_image)
  var r_image = region(ispace(int2d, size_image), Pixel)

  -- Create a sub-region for the interior part of image
  var p_interior = create_interior_partition(r_image)
  var r_interior = p_interior[0]

  -- Create an equal partition of the interior image
  var p_private_colors = ispace(int2d, factorize(config.parallelism))
  var p_private = partition(equal, r_interior, p_private_colors)

  -- Create a halo partition for ghost access
  var c_halo = coloring.create()
  for color in p_private_colors do
    var bounds = p_private[color].bounds
    -- TODO: Calculate the correct bounds of the halo
    var halo_bounds : rect2d = rect2d{bounds.lo - {2,2}, bounds.hi + {2,2}}
    coloring.color_domain(c_halo, color, halo_bounds)
  end
  --
  -- TODO: Create an aliased partition of region 'r_image' using coloring 'c_halo':
  var p_halo = partition(aliased, r_image, c_halo, p_private_colors)
  --
  coloring.destroy(c_halo)

  var token = initialize(r_image, config.filename_image)

  -- the execution fence ensures everything before this line has finished before we start the timer
  __fence(__execution,__block)
  var ts_start = c.legion_get_current_time_in_micros()

  --
  -- TODO: Change the following task launches so they are launched for
  --       each of the private regions and its halo region.
  --
  for color in p_halo.colors do
    smooth(p_halo[color], p_private[color])
  end
  for color in p_halo.colors do
    sobelX(p_halo[color], p_private[color])
  end
  for color in p_halo.colors do
    sobelY(p_halo[color], p_private[color])
  end
  for color in p_halo.colors do
    suppressNonmax(p_halo[color], p_private[color])
  end

  --
  -- Launch task 'edgefromGradient' for each of the private regions.
  -- This will be optimized to a parallel task launch.
  --
  for color in p_private.colors do
    edgeFromGradient(p_private[color], config.threshold)
  end

  -- the execution fence ensures everything before this line has finished before we stop the timer
  __fence(__execution,__block)
  var ts_end = c.legion_get_current_time_in_micros()
  c.printf("Total time: %.6f sec.\n", (ts_end - ts_start) * 1e-6)

  saveEdge(r_image, config.filename_edge)
end

regentlib.start(toplevel)
-- local target = os.getenv("OBJNAME")
-- regentlib.saveobj(target, toplevel, "executable")
