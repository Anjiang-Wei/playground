import networkx as nx
import pandas as pd
import matplotlib.pyplot as plt
import json
from cpm import CPM
import sys
import os
import pickle

def create_graph(app, dump=True):
    pickle_file = f"{app}/graph.pickle"

    if os.path.exists(pickle_file):
        # Load the graph from the pickle file
        with open(pickle_file, 'rb') as f:
            G = pickle.load(f)
        print(f"Graph loaded from {pickle_file}")
    else:
        # Load the TSV data into a DataFrame
        df = pd.read_csv(f"{app}/{app}_combined.tsv", sep="\t")

        # Strip leading/trailing spaces from column names
        df.columns = df.columns.str.strip()

        # Strip leading/trailing spaces from all cell values
        df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)

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

        print("Graph created")

        if dump:
            with open(pickle_file, 'wb') as f:
                pickle.dump(G, f)
            print(f"Graph dumped to {pickle_file}")

    return G

def dump_critical_path_to_json(critical_path, file_name):
    # Format the critical path data as specified
    data = [{"tuple": [0, 0, node], "obj": []} for node in critical_path]
    
    # Write to JSON file
    with open(file_name, 'w') as f:
        json.dump(data, f, indent=4)
    
    print(f"Critical path dumped to {file_name}")

def compute_critical_path(G, app, dump=True):
    # Only retain nodes with "<" in title
    nodes_to_retain = [node for node, attr in G.nodes(data=True) if '<' in attr.get('title', '')]
    H = G.subgraph(nodes_to_retain)

    # Remove nodes without edges
    nodes_with_edges = list(set([node for edge in H.edges for node in edge]))
    H = H.subgraph(nodes_with_edges)

    newG = CPM()
    newG.add_nodes_from(H.nodes(data=True))
    newG.add_edges_from(H.edges())
    critical_path_length = newG.critical_path_length
    critical_path = newG.critical_path

    print("CPM method's Critical Path:", critical_path)
    newG.validate_first_element()
    # Retrieve the titles of the nodes on the critical path
    critical_path_titles = [newG.nodes[node]['title'] for node in critical_path]
    print("First 10 elements on the critical path:", critical_path_titles[:10])

    print("Max Execution Time:", critical_path_length)

    if dump:
        file_name = f'/scratch2/anjiang/public_html/{app}_test/json/critical_path.json'
        dump_critical_path_to_json(critical_path, file_name)

if __name__ == "__main__":
    app = sys.argv[1]
    G = create_graph(app)
    compute_critical_path(G, app)
