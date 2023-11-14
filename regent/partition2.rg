import "regent"

local c = regentlib.c

fspace Node {
    id : int64
}

fspace Edge(r: region(Node)) {
    source_node: ptr(Node, r),
    dest_node  : ptr(Node, r),
}

task main()
    var num_parts = 4
    var num_elements = 20

    var nodes = region(ispace(ptr, num_elements), Node)
    var edges = region(ispace(ptr, num_elements - 1), Edge(nodes))

    var i = 0
    for node in nodes do
        nodes[node].id = i
        i += 1
    end

    var j = 0
    for edge in edges do
        edges[edge].source_node = unsafe_cast(ptr(Node, nodes), j)
        edges[edge].dest_node = unsafe_cast(ptr(Node, nodes), j + 1)
        j += 1
    end
    
    for edge in edges do
        c.printf("from %d to %d\n", edge.source_node.id, edge.dest_node.id)
    end

    -- partition the edge first
    var colors = ispace(int1d, num_parts)
    var edge_partition = partition(equal, edges, colors)

    for color in edge_partition.colors do
        c.printf("Edge subregion %d:\n", color)
        for e in edge_partition[color] do
            c.printf("from %d to %d\n", e.source_node.id, e.dest_node.id)
        end
        c.printf("\n")
    end

    -- partition the nodes with image(parent_region, source_region, data_region.field)
    var node_partition = image(nodes, edge_partition, edges.source_node)
    for color in node_partition.colors do
        c.printf("Node subregion %d: ", color)
        for n in node_partition[color] do
            c.printf("%d ", n.id)
        end
        c.printf("\n")
    end

    c.printf("-------------------\n")

    var node_partition2 = image(nodes, edge_partition, edges.dest_node)
    for color in node_partition2.colors do
        c.printf("Node subregion %d: ", color)
        for n in node_partition2[color] do
            c.printf("%d ", n.id)
        end
        c.printf("\n")
    end
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")