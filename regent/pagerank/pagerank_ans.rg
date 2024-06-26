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
    -- TODO: Initialize your fields if you need to
    page.next_rank = 0.0
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

task compute_next_rank(r_pages   : region(Page),
                       r_links   : region(Link(r_pages)),
                       damp      : double,
                       err_bound : double,
                       num_pages : int32)
where
  reads(r_pages.rank, r_links, r_pages.next_rank, r_pages.out_degree), writes(r_pages.next_rank, r_pages.rank)
do
  for page in r_pages do
    page.next_rank = 0
  end
  for link in r_links do
    var u_src = link.source_node
    var v_dest = link.dest_node
    r_pages[v_dest].next_rank += r_pages[u_src].rank / r_pages[u_src].out_degree
  end
  var dist : double = 0.0f
  for page in r_pages do
    page.next_rank = (1 - damp) / num_pages + damp * page.next_rank
    dist += (page.rank - page.next_rank) * (page.rank - page.next_rank)
    page.rank = page.next_rank
  end
  return dist <= err_bound * err_bound
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
  c.printf("**********************************\n")

  -- Create a region of pages and a region of links
  var r_pages = region(ispace(ptr, config.num_pages), Page)
  var r_links = region(ispace(ptr, config.num_links), Link(wild))

  -- Initialize the page graph from a file
  initialize_graph(r_pages, r_links, config.damp, config.num_pages, config.input)

  var num_iterations = 0
  var converged = false
  __fence(__execution,__block)
  var ts_start = c.legion_get_current_time_in_micros()
  while not converged do
    num_iterations += 1
    --
    -- TODO: Launch the tasks that you implemented above.
    --       (and of course remove the break statement here.)
    --
    -- break
    if num_iterations > config.max_iterations then
      break
    else
      converged = compute_next_rank(r_pages, r_links, config.damp, config.error_bound, config.num_pages)
    end
  end
  -- We don't need an execution fence here because the test on "converged" in the while loop above will depend
  -- on the tasks of the while loop body completing.
  var ts_stop = c.legion_get_current_time_in_micros()
  c.printf("PageRank converged after %d iterations in %.4f sec\n",
    num_iterations, (ts_stop - ts_start) * 1e-6)

  if config.dump_output then dump_ranks(r_pages, config.output) end
end

-- regentlib.start(toplevel)
local target = os.getenv("OBJNAME")
regentlib.saveobj(toplevel, target, "executable")