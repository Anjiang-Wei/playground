import sys
from graph import create_graph, compute_critical_path
from bubble import report_task_stats, report_bubble_stats, compute_bubbles

def analyze_app(app):
    G = create_graph(app)
    critical_path = compute_critical_path(G, app, dump=False)
    bubbles = compute_bubbles(G, critical_path)
    task_summary_ms = report_task_stats(G, critical_path)
    bubble_summary_ms = report_bubble_stats(G, bubbles, critical_path)
    critical_path_time = G.nodes[critical_path[-1]]['end'] - G.nodes[critical_path[0]]['start']
    return task_summary_ms, bubble_summary_ms, critical_path_time

def differential_analysis(summary1, summary2, key, total_diff):
    diff = {}
    for k, v1 in summary1.items():
        if k in summary2:
            v2 = summary2[k]
            difference = v1[key] - v2[key]
            diff[k] = {
                'difference_ms': difference,
                'percentage_of_total_diff': (difference / total_diff) * 100 if total_diff != 0 else 0
            }
        else:
            difference = v1[key]
            diff[k] = {
                'difference_ms': difference,
                'percentage_of_total_diff': (difference / total_diff) * 100 if total_diff != 0 else 0
            }
    for k, v2 in summary2.items():
        if k not in diff:
            difference = -v2[key]
            diff[k] = {
                'difference_ms': difference,
                'percentage_of_total_diff': (difference / total_diff) * 100 if total_diff != 0 else 0
            }
    return sorted(diff.items(), key=lambda x: abs(x[1]['difference_ms']), reverse=True)

def truncate_name(name, max_length=80):
    return (name[:max_length-3] + '...') if len(name) > max_length else name

def print_combined_diff_report(app1, app2, combined_diff, total_critical_path_diff, critical_path_time1, critical_path_time2):
    print("\nCombined Differential Analysis of Task Execution and Bubble Duration (in ms):")
    header = f"{'Name':<80} {'Difference (ms)':>20} {'Percentage of Total Diff':>30}"
    print(header)
    print("-" * len(header))
    total_diff_sum = 0
    total_percentage_sum = 0
    for name, data in combined_diff:
        truncated_name = truncate_name(name)
        total_diff_sum += data['difference_ms']
        total_percentage_sum += data['percentage_of_total_diff']
        print(f"{truncated_name:<80} {data['difference_ms']:>20.2f} {data['percentage_of_total_diff']:>30.2f}")

    print(f"\nTotal of Differences: {total_diff_sum:.2f} ms")
    print(f"Sum of Percentages: {total_percentage_sum:.2f}%")
    critical_path_time1 /= 1000
    critical_path_time2 /= 1000
    print(f"\nCritical Path Time for {app1}: {critical_path_time1:.2f} ms")
    print(f"Critical Path Time for {app2}: {critical_path_time2:.2f} ms")
    print(f"Total Critical Path Time Difference: {total_critical_path_diff:.2f} ms, percentage: {(total_critical_path_diff / critical_path_time1) * 100:.2f}%\n")

def main(app1, app2):
    task_summary_ms1, bubble_summary_ms1, critical_path_time1 = analyze_app(app1)
    task_summary_ms2, bubble_summary_ms2, critical_path_time2 = analyze_app(app2)

    # Compute total critical path time difference
    total_critical_path_diff = (critical_path_time1 - critical_path_time2) / 1000

    # Differential analysis for task execution time
    task_diff = differential_analysis(task_summary_ms1, task_summary_ms2, 'total_execution_ms', total_critical_path_diff)

    # Differential analysis for bubble duration
    bubble_diff = differential_analysis(bubble_summary_ms1, bubble_summary_ms2, 'total_duration_ms', total_critical_path_diff)

    # Combine task and bubble differences into a single summary report
    combined_diff = {
        **{f"Task: {k}": v for k, v in task_diff},
        **{f"Bubble: {k}": v for k, v in bubble_diff}
    }
    combined_diff = sorted(combined_diff.items(), key=lambda x: abs(x[1]['difference_ms']), reverse=True)

    print_combined_diff_report(app1, app2, combined_diff, total_critical_path_diff, critical_path_time1, critical_path_time2)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python diff.py <app1> <app2>")
        sys.exit(1)

    app1 = sys.argv[1]
    app2 = sys.argv[2]

    main(app1, app2)
