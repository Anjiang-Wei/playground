import "regent"

-- Helper module to handle command line arguments
local PageRankConfig = require("pagerank_config")

local c = regentlib.c

fspace Page {
  rank         : double,
  --
  -- TODO: Add more fields as you need.
  --
  next_rank    : double,
  out_degree   : int32,
}

--
-- TODO: Define fieldspace 'Link' which has two pointer fields,
--       one that points to the source and another to the destination.
--
-- fspace Link(...) { ... }
fspace Link(r: region(Page)) {
  source_node : ptr(Page, r),
  dest_node: ptr(Page, r),
}

fspace Diff
{
  value : double,
}

terra skip_header(f : &c.FILE)
  var x : uint64, y : uint64
  c.fscanf(f, "%llu\n%llu\n", &x, &y)
end

terra read_ids(f : &c.FILE, page_ids : &uint32)
  return c.fscanf(f, "%d %d\n", &page_ids[0], &page_ids[1]) == 2
end

task initialize_graph(r_pages   : region(Page),
                      --
                      -- TODO: Give the right region type here.
                      --
                      r_links   : region(Link(r_pages)),
                      damp      : double,
                      num_pages : uint64,
                      filename  : int8[512])
where
  reads writes(r_pages, r_links)
do
  var ts_start = c.legion_get_current_time_in_micros()
  for page in r_pages do
    page.rank = 1.0 / num_pages
    -- TODO: Initialize your fields if you need
    page.next_rank = (1.0 - damp) / num_pages
    page.out_degree = 0
  end

  var f = c.fopen(filename, "rb")
  skip_header(f)
  var page_ids : uint32[2]
  for link in r_links do
    regentlib.assert(read_ids(f, page_ids), "Less data that it should be")
    var src_page = unsafe_cast(ptr(Page, r_pages), page_ids[0])
    var dst_page = unsafe_cast(ptr(Page, r_pages), page_ids[1])
    --
    -- TODO: Initialize the link with 'src_page' and 'dst_page'
    --
    link.source_node = src_page
    link.dest_node = dst_page
    r_pages[src_page].out_degree += 1
  end
  c.fclose(f)
  var ts_stop = c.legion_get_current_time_in_micros()
  c.printf("Graph initialization took %.4f sec\n", (ts_stop - ts_start) * 1e-6)
end

--
-- TODO: Implement PageRank. You can use as many tasks as you want.
--
task zero(r_pages : region(Page),
        damp      : double,
        err_bound : double,
        num_pages : int32)
where writes(r_pages.next_rank)
do
  for page in r_pages do
    page.next_rank = (1.0 - damp) / num_pages
  end
end
task compute_next_rank(r_pages   : region(Page),
                       r_links   : region(Link(r_pages)),
                       damp      : double,
                       err_bound : double,
                       num_pages : int32)
where
  reads(r_pages.{rank,out_degree}, r_links), reduces +(r_pages.next_rank)
do
  for link in r_links do
    var u_src = link.source_node
    var v_dest = link.dest_node
    r_pages[v_dest].next_rank += damp * r_pages[u_src].rank / r_pages[u_src].out_degree
  end
end

task update_rank(r_pages   : region(Page),
                -- r_links   : region(Link(r_pages)),
                 damp      : double,
                 err_bound : double,
                 num_pages : int32)
where reads(r_pages.{next_rank,rank}), reduces +(r_pages.rank)
do
  var dist : double = 0.0f
  for page in r_pages do
    var one_diff = page.next_rank - page.rank
    dist += one_diff * one_diff
    page.rank += one_diff
  end
  return dist
end

task sum(dist : region(ispace(int1d), Diff))
where reads(dist.value)
do
  var sum: double = 0.0
  for p in dist do
    sum += p.value
  end
  return sum
end


task dump_ranks(r_pages  : region(Page),
                filename : int8[512])
where
  reads(r_pages.rank)
do
  var f = c.fopen(filename, "w")
  for page in r_pages do c.fprintf(f, "%g\n", page.rank) end
  c.fclose(f)
end

task toplevel()
  var config : PageRankConfig
  config:initialize_from_command()
  c.printf("**********************************\n")
  c.printf("* PageRank                       *\n")
  c.printf("*                                *\n")
  c.printf("* Number of Pages  : %11lu *\n",  config.num_pages)
  c.printf("* Number of Links  : %11lu *\n",  config.num_links)
  c.printf("* Damping Factor   : %11.4f *\n", config.damp)
  c.printf("* Error Bound      : %11g *\n",   config.error_bound)
  c.printf("* Max # Iterations : %11u *\n",   config.max_iterations)
  c.printf("* # Parallel Tasks : %11u *\n",   config.parallelism)
  c.printf("**********************************\n")

  -- Create a region of pages
  var r_pages = region(ispace(ptr, config.num_pages), Page)
  var r_links = region(ispace(ptr, config.num_links), Link(wild))
  var r_diff = region(ispace(int1d, config.parallelism), Diff)

  --
  -- TODO: Create partitions for links and pages.
  --       You can use as many partitions as you want.
  --


  -- Initialize the page graph from a file
  initialize_graph(r_pages, r_links, config.damp, config.num_pages, config.input)
  for e in r_diff do
    e.value = 0.0
  end

  var colors = ispace(int1d, config.parallelism)
  var p_links = partition(equal, r_links, colors)
  var p_page_src = image(r_pages, p_links, r_links.source_node)
  var p_page_dest = image(r_pages, p_links, r_links.dest_node)
  var p_page_full = partition(equal, r_pages, colors)
  var p_page = p_page_src | p_page_dest

  var num_iterations = 0
  var converged = false
  var ts_start = c.legion_get_current_time_in_micros()
  while not converged do
    num_iterations += 1
    -- reset the timer starting in the third iteration, thereby ignoring the runtime warmup in the first two iterations
    if num_iterations == 3 then
      ts_start = c.legion_get_current_time_in_micros()
    end
    --
    -- TODO: Launch the tasks that you implemented above.
    --       (and of course remove the break statement here.)
    --
    if num_iterations > config.max_iterations then
      break
    else
      for color in colors do
        zero(p_page_full[color], config.damp, config.error_bound, config.num_pages)
      end
      for color in colors do
        compute_next_rank(p_page[color], p_links[color], config.damp, config.error_bound, config.num_pages)
      end
      for color in colors do
        r_diff[color].value = update_rank(p_page_full[color], config.damp, config.error_bound, config.num_pages)
      end
      var dist_sum = sum(r_diff)
      converged = dist_sum <= config.error_bound * config.error_bound
    end
  end
  var ts_stop = c.legion_get_current_time_in_micros()
  c.printf("PageRank converged after %d iterations in %.4f sec\n",
    num_iterations, (ts_stop - ts_start) * 1e-6)

  if config.dump_output then dump_ranks(r_pages, config.output) end
end

regentlib.start(toplevel)
