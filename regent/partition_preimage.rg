import "regent"

local c = regentlib.c

fspace Node {
    id : int64
}

fspace Edge(r: region(Node)) {
    source_node : ptr(Node, r),
    dest_node:    ptr(Node, r),
}

task main()
    var num_elements = 20

    var nodes = region(ispace(ptr, num_elements), Node)
    var edges = region(ispace(ptr, num_elements-1), Edge(nodes))

    var i = 0
    for node in nodes do
        node.id = i
        i += 1
    end
    
    var j = 0
    for edge in edges do
        for n in nodes do
            for m in nodes do
                if n.id == j and m.id == j+1 then
                    edge.source_node = n
                    edge.dest_node = m
                end
            end
        end
        j += 1
    end
    for edge in edges do
        c.printf("from %d to %d\n", edges[edge].source_node.id, edges[edge].dest_node.id)
    end

    -- euqual partition for the nodes
    var num_parts = 4
    var colors = ispace(int1d, num_parts)
    var node_partition = partition(equal, nodes, colors)

    for color in node_partition.colors do
        c.printf("Node subregion %d\n", color)
        for n in node_partition[color] do
            c.printf("%d ", n.id)
        end
        c.printf("\n")
    end

    -- partition the edges region based on the node partition.
    -- For each subregion of nodes, collect all edges with one node
    -- in that subregion as its source
    -- preimage(parent_region, target_partition, data_region.field)
    var edge_partition = preimage(edges, node_partition, edges.source_node)
    
    for color in edge_partition.colors do
        c.printf("Edge subregion %d\n", color)
        for e in edge_partition[color] do
            c.printf("(%d,%d) ", e.source_node.id, e.dest_node.id)
        end
        c.printf("\n")
    end
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")