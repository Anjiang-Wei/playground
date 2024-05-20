import networkx as nx
import pandas as pd
import matplotlib.pyplot as plt
import json
from cpm import CPM
import sys

app = sys.argv[1]
# Load the TSV data into a DataFrame
df = pd.read_csv(f"{app}/{app}_combined.tsv", sep="\t")

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
    row_in = str(row['in']).strip()
    if pd.notna(row['in']):
        in_edges = [int(float(x.strip())) for x in row_in.split(',')]
        for in_edge in in_edges:
            G.add_edge(row['prof_uid'], in_edge)


# Now the graph G contains all nodes and edges, and can be queried for attributes

# Only retain nodes with "<" in title
nodes_to_retain = [node for node, attr in G.nodes(data=True) if '<' in attr.get('title', '')]
G = G.subgraph(nodes_to_retain)

# Remove nodes without edges
nodes_with_edges = list(set([node for edge in G.edges for node in edge]))
G = G.subgraph(nodes_with_edges)

print("nodes with edges computed")


print("nodes retained")

# Create labels using 'title' and 'prof_uid'
labels = {node_id: attr['title'] + ' (' + str(attr['prof_uid']) + ')' for node_id, attr in G.nodes(data=True)}

# Function to find all paths in the graph

def dump_critical_path_to_json(critical_path, file_name=f'/scratch2/anjiang/public_html/{app}_test/json/critical_path.json'):
    # Format the critical path data as specified
    data = [{"tuple": [0, 0, node], "obj": []} for node in critical_path]
    
    # Write to JSON file
    with open(file_name, 'w') as f:
        json.dump(data, f, indent=4)
    
    print(f"Critical path dumped to {file_name}")


def compute_critical_path(H):
    newG = CPM()
    newG.add_nodes_from(H.nodes(data=True))
    newG.add_edges_from(H.edges())
    critical_path_length = newG.critical_path_length
    critical_path = newG.critical_path

    print("CPM method's Critical Path:", critical_path)
    newG.validate_first_element()
    # Retrieve the titles of the nodes on the critical path
    critical_path_titles = [newG.nodes[node]['title'] for node in critical_path]
    print("Titles of the elements on the critical path:", critical_path_titles)

    print("Max Execution Time:", critical_path_length)
    dump_critical_path_to_json(critical_path)

compute_critical_path(G)

# Visualize the graph using spring layout
# plt.figure(figsize=(40, 40))
# pos = nx.spring_layout(G)#, k=2)  # Adjust the k parameter for better spacing
# nx.draw(G, pos, labels=labels, with_labels=True, node_size=5000, node_color="lightblue", font_size=30, font_weight="bold", arrows=True, arrowstyle='-|>', arrowsize=30)
# plt.title("Graph Visualization")

# # Save the visualization as a PDF
# plt.savefig(f"{app}/{app}.pdf")