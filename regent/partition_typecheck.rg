import "regent"

local c = regentlib.c

fspace Node {
    id: int64,
}

fspace Edge(r: region(Node)) {
    source_node : ptr(Node, r),
    dest_node: ptr(Node, r),
}

task edge_update(nodes: region(Node), edges: region(Edge(nodes)))
where
    reads (nodes, edges)
do
    for e in edges do
        c.printf("(%d, %d) ", e.source_node.id, e.dest_node.id)
    end
    c.printf("\n")
end

task main()
    var num_parts = 4
    var num_elements = 20
    
    var nodes = region(ispace(ptr, num_elements), Node)
    -- var edges = region(ispace(ptr, num_elements - 1), Edge(nodes))
    var edges = region(ispace(ptr, num_elements - 1), Edge(wild))

    var i = 0
    for node in nodes do
        node.id = i
        i += 1
    end
    var j = 0
    for edge in edges do
        edge.source_node = unsafe_cast(ptr(Node, nodes), j)
        edge.dest_node = unsafe_cast(ptr(Node, nodes), j + 1)
        j += 1
    end

    var colors = ispace(int1d, num_parts)
    var edge_partition = partition(equal, edges, colors)

    -- -- after applying 'wild', the following code does not typecheck
    -- for color in edge_partition.colors do
    --     c.printf("Edge subregion %d: ", color)
    --     for e in edge_partition[color] do
    --         c.printf("(%d, %d) ", e.source_node.id, e.dest_node.id)
    --     end
    --     c.printf("\n")
    -- end

    var node_partition_upper = image(nodes, edge_partition, edges.dest_node)
    var node_partition_lower = image(nodes, edge_partition, edges.source_node)
    var private_nodes_partition = node_partition_upper & node_partition_lower
    var private_edge_partition = preimage(edges, private_nodes_partition, edges.dest_node)

    for color in private_nodes_partition.colors do
        c.printf("Private node subregion %d: ", color)
        for n in private_nodes_partition[color] do
            c.printf("%d ", n.id)
        end
        c.printf("\n")
    end

    for color in private_edge_partition.colors do
        c.printf("Private edge subregion %d\n", color)
        -- edge_update(private_nodes_partition[color], private_edge_partition[color]) -- this does not typecheck if not using wild
        -- error message is:  type mismatch in argument 2: expected region(Edge($188)) but got region(Edge($nodes))
        -- region type cast is unimplemented
        -- edge_update(private_nodes_partition[color], [region(Edge(private_nodes_partition[color]))] (private_edge_partition[color]))
        edge_update(private_nodes_partition[color], private_edge_partition[color])
        __fence(__execution, __block)
    end
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")