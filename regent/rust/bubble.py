import sys
from graph import create_graph, compute_critical_path

def find_overlapping_nodes(G, bubble_start_time, bubble_end_time):
    '''
    Find nodes that overlap with the given time range.
    Return their prof_uid and title.
    '''
    overlapping_nodes = []
    for node, data in G.nodes(data=True):
        node_start_time = data.get('start', float('inf'))
        node_end_time = data.get('end', float('-inf'))
        overlap_time = min(node_end_time, bubble_end_time) - max(node_start_time, bubble_start_time)
        overlap_perc = overlap_time / (bubble_end_time - bubble_start_time) * 100.0
        if node_start_time < bubble_end_time and node_end_time > bubble_start_time:
            overlapping_nodes.append({
                'prof_uid': data.get('prof_uid'),
                'title': data.get('title'),
                'overlap_time': overlap_time,
                'overlap_perc': overlap_perc
            })
    overlapping_nodes = sorted(overlapping_nodes, key=lambda x: x['overlap_time'], reverse=True)
    return overlapping_nodes

def compute_bubbles(G, critical_path):
    '''
    For each element on the critical path,
    the bubble's 'start_time' is the previous element's 'end',
    the bubble's 'end_time' is the current element's 'start'
    Then we insert all the bubbles into a list.
    '''
    bubbles = []
    for i in range(1, len(critical_path)):
        prev_node = critical_path[i - 1]
        curr_node = critical_path[i]

        bubble_start_time = G.nodes[prev_node]['end']
        bubble_end_time = G.nodes[curr_node]['start']

        # Find overlapping nodes
        overlapping_nodes = find_overlapping_nodes(G, bubble_start_time, bubble_end_time)
        overlap_prof_uid = [node['prof_uid'] for node in overlapping_nodes]
        overlap_title = [node['title'] for node in overlapping_nodes]
        overlap_time = [node['overlap_time'] for node in overlapping_nodes]
        overlap_perc = [node['overlap_perc'] for node in overlapping_nodes]

        bubbles.append({
            'b_start': bubble_start_time,
            'b_end': bubble_end_time,
            'duration': bubble_end_time - bubble_start_time,
            'overlap_prof_uid': overlap_prof_uid,
            'overlap_title': overlap_title,
            'overlap_time': overlap_time,
            'overlap_perc': overlap_perc,
            'prev': prev_node,
            'curr': curr_node
        })
    
    # Sort bubbles based on the 'duration'
    bubbles = sorted(bubbles, key=lambda x: x['duration'], reverse=True)

    return bubbles

if __name__ == "__main__":
    app = sys.argv[1]
    G = create_graph(app)
    critical_path = compute_critical_path(G, app, dump=False)
    bubbles = compute_bubbles(G, critical_path)

    for bubble in bubbles[:5]:
        print(f"Bubble Start Time: {bubble['b_start']}, Bubble End Time: {bubble['b_end']}, Duration: {bubble['duration']}")
        print(f"Between Nodes: {G.nodes[bubble['prev']]['title']} -> {G.nodes[bubble['curr']]['title']}")
        # print(f"Overlapping Nodes Prof UID: {bubble['overlap_prof_uid']}")
        print(f"Overlapping Nodes Title: {bubble['overlap_title'][:5]}")
        print(f"Overlapping Nodes Duration: {bubble['overlap_time'][:5]}")
        print(f"Overlapping Nodes Percentage: {bubble['overlap_perc'][:5]}")
        print()
