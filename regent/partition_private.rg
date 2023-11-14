import "regent"

local c = regentlib.c

fspace Node {
    id: int64,
}

fspace Edge(r: region(Node)) {
    source_node: ptr(Node, r),
    dest_node: ptr(Node, r),
}

task main()
    var num_elements = 20
    var num_partitions = 4

    var nodes = region(ispace(ptr, num_elements), Node)
    var edges = region(ispace(ptr, num_elements - 1), Edge(nodes))

    var i = 0
    for node in nodes do
        node.id = i
        i += 1
    end

    var j = 0
    for edge in edges do
        edge.source_node = unsafe_cast(ptr(Node, nodes), j)
        edge.dest_node = unsafe_cast(ptr(Node, nodes), j+1)
        j += 1
    end

    var colors = ispace(int1d, num_partitions)
    var edge_partition = partition(equal, edges, colors)

    for color in edge_partition.colors do
        c.printf("Edge subregion %d\n", color)
        for e in edge_partition[color] do
            c.printf("(%d, %d) ", e.source_node.id, e.dest_node.id)
        end
        c.printf("\n")
    end

    var node_partition_upper = image(nodes, edge_partition, edges.dest_node)
    var node_partition_lower = image(nodes, edge_partition, edges.source_node)

    var private_nodes_partition = node_partition_upper & node_partition_lower
    var private_edges_partition = preimage(edges, private_nodes_partition, edges.dest_node)

    for color in private_nodes_partition.colors do
        c.printf("Private node subregion %d\n", color)
        for n in private_nodes_partition[color] do
            c.printf("%d ", n.id)
        end
        c.printf("\n")
    end

    for color in private_edges_partition.colors do
        c.printf("Private edge subregion %d\n", color)
        for e in private_edges_partition[color] do
            c.printf("(%d, %d) ", e.source_node.id, e.dest_node.id)
        end
        c.printf("\n")
    end
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")

-- Edge subregion 0
-- (0, 1) (1, 2) (2, 3) (3, 4) 
-- Edge subregion 1
-- (4, 5) (5, 6) (6, 7) (7, 8) (8, 9) 
-- Edge subregion 2
-- (9, 10) (10, 11) (11, 12) (12, 13) (13, 14) 
-- Edge subregion 3
-- (14, 15) (15, 16) (16, 17) (17, 18) (18, 19) 
-- Private node subregion 0
-- 1 2 3 
-- Private node subregion 1
-- 5 6 7 8 
-- Private node subregion 2
-- 10 11 12 13 
-- Private node subregion 3
-- 15 16 17 18 
-- Private edge subregion 0
-- (0, 1) (1, 2) (2, 3) 
-- Private edge subregion 1
-- (4, 5) (5, 6) (6, 7) (7, 8) 
-- Private edge subregion 2
-- (9, 10) (10, 11) (11, 12) (12, 13) 
-- Private edge subregion 3
-- (14, 15) (15, 16) (16, 17) (17, 18)