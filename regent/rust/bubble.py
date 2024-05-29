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

def report_task_stats(G, critical_path):
    # Summarize execution time by task name
    task_summary = {}
    for node in critical_path:
        title = G.nodes[node]['title']
        task_name = title.split('<')[0].strip()
        execution = G.nodes[node]['execution']
        if task_name not in task_summary:
            task_summary[task_name] = {'total_execution': 0, 'count': 0}
        task_summary[task_name]['total_execution'] += execution
        task_summary[task_name]['count'] += 1

    total_execution_time = sum(data['total_execution'] for data in task_summary.values())
    critical_path_time = G.nodes[critical_path[-1]]['end'] - G.nodes[critical_path[0]]['start']
    execution_percentage_of_critical_path = (total_execution_time / critical_path_time) * 100

    # Convert execution time to milliseconds and calculate average execution time
    task_summary_ms = {
        task_name: {
            'total_execution_ms': data['total_execution'] / 1000,
            'count': data['count'],
            'average_execution_ms': (data['total_execution'] / data['count']) / 1000,
            'percentage': (data['total_execution'] / total_execution_time) * 100
        }
        for task_name, data in task_summary.items()
    }
    sorted_task_summary = sorted(task_summary_ms.items(), key=lambda x: x[1]['total_execution_ms'], reverse=True)

    print("\nExecution Time Summary by Task Name (in ms):")
    header = f"{'Task Name':<30} {'Total Execution Time (ms)':>25} {'Counts':>12} {'Average Execution Time (ms)':>28} {'Percentage':>12}"
    print(header)
    print("-" * len(header))
    for task_name, data in sorted_task_summary:
        print(f"{task_name:<30} {data['total_execution_ms']:>25.2f} {data['count']:>12} {data['average_execution_ms']:>28.2f} {data['percentage']:>12.2f}")

    print(f"\nTotal Execution Time: {total_execution_time / 1000:.2f} ms")
    print(f"Percentage of Critical Path: {execution_percentage_of_critical_path:.2f}%")
    return task_summary_ms

def report_bubble_stats(G, bubbles, critical_path):
    bubble_time = sum(bubble['duration'] for bubble in bubbles)
    critical_path_time = G.nodes[critical_path[-1]]['end'] - G.nodes[critical_path[0]]['start']
    bubble_percentage_of_critical_path = (bubble_time / critical_path_time) * 100

    # Summarize bubble time by task name tuple (prev -> curr)
    bubble_summary = {}
    for bubble in bubbles:
        prev_title = G.nodes[bubble['prev']]['title'].split('<')[0].strip()
        curr_title = G.nodes[bubble['curr']]['title'].split('<')[0].strip()
        bubble_name = f"{prev_title:<30} -> {curr_title:<30}"
        if bubble_name not in bubble_summary:
            bubble_summary[bubble_name] = {'total_duration': 0, 'count': 0}
        bubble_summary[bubble_name]['total_duration'] += bubble['duration']
        bubble_summary[bubble_name]['count'] += 1

    # Convert bubble duration to milliseconds and sort by total duration
    bubble_summary_ms = {
        bubble_name: {
            'total_duration_ms': data['total_duration'] / 1000,
            'count': data['count'],
            'average_duration_ms': (data['total_duration'] / data['count']) / 1000,
            'percentage': (data['total_duration'] / bubble_time) * 100
        }
        for bubble_name, data in bubble_summary.items()
    }
    sorted_bubble_summary = sorted(bubble_summary_ms.items(), key=lambda x: x[1]['total_duration_ms'], reverse=True)

    print("\nBubble Time Summary by Task Name Tuple (in ms):")
    header = f"{'Bubble Name':<70} {'Total Duration (ms)':>25} {'Counts':>12} {'Average Duration (ms)':>28} {'Percentage':>12}"
    print(header)
    print("-" * len(header))
    for bubble_name, data in sorted_bubble_summary:
        print(f"{bubble_name:<70} {data['total_duration_ms']:>25.2f} {data['count']:>12} {data['average_duration_ms']:>28.2f} {data['percentage']:>12.2f}")

    print(f"\nTotal Bubble Time: {bubble_time / 1000:.2f} ms")
    print(f"Percentage of Critical Path: {bubble_percentage_of_critical_path:.2f}%")
    return bubble_summary_ms

if __name__ == "__main__":
    app = sys.argv[1]
    G = create_graph(app)
    critical_path = compute_critical_path(G, app, dump=False)
    bubbles = compute_bubbles(G, critical_path)

    report_task_stats(G, critical_path)
    report_bubble_stats(G, bubbles, critical_path)
