import sys
import pandas as pd
import json
import warnings

# Suppress pandas FutureWarnings to keep the output clean
warnings.simplefilter(action='ignore', category=FutureWarning)

TASK_FILE = sys.argv[1]
OUTPUT_PATH = sys.argv[2]
REPORT_FORMAT = sys.argv[3].lower()

def generate_report():
    try:
        # Load JSON data into a pandas DataFrame
        with open(TASK_FILE, 'r') as f:
            data = json.load(f)
        
        if not data:
            print("INFO: Task database is empty. Report not generated.", file=sys.stderr)
            return
            
        df = pd.DataFrame(data)

        # Ensure ID and Priority are numeric for sorting and calculations.
        # 'errors='coerce' handles non-numeric/null values gracefully (setting them to 0).
        df['id'] = pd.to_numeric(df['id'], errors='coerce').fillna(0).astype(int)
        df['priority'] = pd.to_numeric(df['priority'], errors='coerce').fillna(0).astype(int)

        # Select and reorder columns for the final report view
        df = df[['id', 'description', 'status', 'priority', 'tags', 'created_at']]
        
        # Sort by priority (descending)
        df = df.sort_values(by='priority', ascending=False)
        
        # Format tags: Convert list of tags into a single comma-separated string for CSV/Excel
        if 'tags' in df.columns:
            df['tags'] = df['tags'].apply(lambda x: ', '.join(map(str, x)) if isinstance(x, list) else x)

        if REPORT_FORMAT == 'excel':
            output_file = f"{OUTPUT_PATH}/AIWAS_Task_Report_{pd.Timestamp.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
            df.to_excel(output_file, index=False, sheet_name='AIWAS Tasks')
            print(f"SUCCESS: Excel report generated at {output_file}")
            
        elif REPORT_FORMAT == 'csv':
            output_file = f"{OUTPUT_PATH}/AIWAS_Task_Report_{pd.Timestamp.now().strftime('%Y%m%d_%H%M%S')}.csv"
            df.to_csv(output_file, index=False)
            print(f"SUCCESS: CSV report generated at {output_file}")
            
        else:
            print(f"ERROR: Unsupported report format: {REPORT_FORMAT}", file=sys.stderr)

    except FileNotFoundError:
        print(f"ERROR: Task file not found at {TASK_FILE}", file=sys.stderr)
    except Exception as e:
        # Print the exact error if report generation fails
        print(f"ERROR: Report generation failed: {e}", file=sys.stderr)

if __name__ == "__main__":
    generate_report()