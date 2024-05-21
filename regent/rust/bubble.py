import sys
from graph import create_graph, compute_critical_path

if __name__ == "__main__":
    app = sys.argv[1]
    G = create_graph(app)
    compute_critical_path(G, app, dump=False)
