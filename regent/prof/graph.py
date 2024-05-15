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
            G.add_edge(row['prof_uid'], in_edge)

# Function to validate the "out" column
def validate_out_column(graph, df):
    for index, row in df.iterrows():
        if pd.notna(row['out']) and row['out'].strip():
            out_edges = [int(x.strip()) for x in row['out'].split(',')]
            for out_edge in out_edges:
                if not graph.has_edge(out_edge, row['prof_uid']):
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
# Only retain nodes with "<" in title
nodes_to_retain = [node for node, attr in H.nodes(data=True) if '<' in attr.get('title', '')]
H = H.subgraph(nodes_to_retain)

# Create labels using 'title' and 'prof_uid'
labels = {node_id: attr['title'] + ' (' + str(attr['prof_uid']) + ')' for node_id, attr in H.nodes(data=True)}

# Function to find all paths in the graph
def find_all_paths(graph):
    all_paths = []
    for start_node in graph.nodes:
        for end_node in graph.nodes:
            if start_node != end_node:
                for path in nx.all_simple_paths(graph, source=start_node, target=end_node):
                    all_paths.append(path)
    return all_paths

# Find all paths in the graph H
all_paths = find_all_paths(H)


def maximum_execution_time():
    # Calculate the total execution time for each path
    path_execution_times = []
    for path in all_paths:
        execution_time = sum(H.nodes[node]['execution'] for node in path if 'execution' in H.nodes[node])
        if len(path) > 1:  # Only consider non-trivial paths
            path_execution_times.append((path, execution_time))

    # Find the critical path
    critical_path, max_execution_time = max(path_execution_times, key=lambda x: x[1], default=([], 0))

    print("Critical Path:", critical_path)
    print("Max Execution Time:", max_execution_time)

maximum_execution_time()

def maximum_spanning_time():
    # Calculate the spanning time for each path
    path_spanning_times = []
    for path in all_paths:
        start_time = H.nodes[path[0]]['start']
        end_time = H.nodes[path[-1]]['end']
        spanning_time = end_time - start_time
        if len(path) > 1:  # Only consider non-trivial paths
            path_spanning_times.append((path, spanning_time))

    # Find the critical path based on maximum spanning time
    critical_path, max_spanning_time = max(path_spanning_times, key=lambda x: x[1], default=([], 0))

    print("Critical Path based on maximum spanning time:", critical_path)
    print("Max Spanning Time:", max_spanning_time)

maximum_spanning_time()

# # Visualize the graph using spring layout
# plt.figure(figsize=(100, 100))
# pos = nx.spring_layout(H, k=2)  # Adjust the k parameter for better spacing
# nx.draw(H, pos, labels=labels, with_labels=True, node_size=5000, node_color="lightblue", font_size=30, font_weight="bold", arrows=True, arrowstyle='-|>', arrowsize=30)
# plt.title("Graph Visualization")

# # Save the visualization as a PDF
# plt.savefig("graph_visualization.pdf")