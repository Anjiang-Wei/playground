import networkx as nx
import pandas as pd
import matplotlib.pyplot as plt

# Load the TSV data into a DataFrame
df = pd.read_csv("combined.tsv", sep="\t")

# Strip leading/trailing spaces from column names
df.columns = df.columns.str.strip()

# Strip leading/trailing spaces from all cell values
df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)

# Print the column names to verify
print("Column names:", df.columns.tolist())

# Create a directed graph
G = nx.DiGraph()

# Add nodes with attributes
for index, row in df.iterrows():
    node_id = row['prof_uid']
    G.add_node(node_id, **row.to_dict())

# Add edges based on the "in" column
for index, row in df.iterrows():
    if pd.notna(row['in']) and row['in'].strip():
        in_edges = [int(x.strip()) for x in row['in'].split(',')]
        for in_edge in in_edges:
            G.add_edge(in_edge, row['prof_uid'])

# Function to validate the "out" column
def validate_out_column(graph, df):
    for index, row in df.iterrows():
        if pd.notna(row['out']) and row['out'].strip():
            out_edges = [int(x.strip()) for x in row['out'].split(',')]
            for out_edge in out_edges:
                if not graph.has_edge(row['prof_uid'], out_edge):
                    return False, row['prof_uid'], out_edge
    return True, None, None

# Validate the "out" column
is_valid, invalid_node, invalid_out_edge = validate_out_column(G, df)

if is_valid:
    print("The graph is valid based on the 'out' column.")
else:
    print(f"Invalid edge: {invalid_node} -> {invalid_out_edge}")

# Now the graph G contains all nodes and edges, and can be queried for attributes

# Example: Querying node attributes
node_id = 14
if node_id in G.nodes:
    print(f"Attributes of node {node_id}: {G.nodes[node_id]}")
else:
    print(f"Node {node_id} not found in the graph.")

# Remove nodes without edges
nodes_with_edges = list(set([node for edge in G.edges for node in edge]))
H = G.subgraph(nodes_with_edges)

# Create labels using 'title' instead of 'prof_uid'
labels = {node_id: attr['title'] for node_id, attr in H.nodes(data=True)}

# Visualize the graph using spring layout
plt.figure(figsize=(50, 50))
pos = nx.spring_layout(H)
nx.draw(H, pos, labels=labels, with_labels=True, node_size=5000, node_color="lightblue", font_size=10, font_weight="bold", arrows=True, arrowstyle='-|>', arrowsize=30)
plt.title("Graph Visualization")

# Save the visualization as a PDF
plt.savefig("graph_visualization.pdf")
# plt.show()