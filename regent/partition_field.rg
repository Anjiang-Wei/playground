import "regent"

local c = regentlib.c

fspace Node {
    id: int64,
    color: int1d,
}

fspace Edge(r: region(Node)) {
    source_node: ptr(Node, r),
    dest_node:   ptr(Node, r),
}

task main()
    var num_parts = 4
    var num_elements = 20
    var nodes = region(ispace(ptr, num_elements), Node)
    var edges = region(ispace(ptr, num_elements-1), Edge(nodes))

    -- color the fields in round-robin fasion
    var i = 0
    for node in nodes do
        node.id = i
        node.color = i % num_parts
        i += 1
    end
    
    var j = 0
    for edge in edges do
        edge.source_node = unsafe_cast(ptr(Node, nodes), j)
        edge.dest_node = unsafe_cast(ptr(Node, nodes), j+1)
        j += 1
    end

    var colors = ispace(int1d, num_parts)
    -- partition by field
    -- partition(region.color_field, color_space)
    var node_partition = partition(nodes.color, colors)
    for color in node_partition.colors do
        c.printf("Node subregion %d\n", color)
        for n in node_partition[color] do
            c.printf("%d ", n.id)
        end
        c.printf("\n")
    end
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")