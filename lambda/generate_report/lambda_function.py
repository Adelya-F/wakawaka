import json
import os
import boto3
import psycopg2
from datetime import datetime, timedelta
import pandas as pd
from io import BytesIO

DB_HOST = os.environ.get('DB_HOST')
DB_NAME = os.environ.get('DB_NAME')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
S3_BUCKET = os.environ.get('S3_BUCKET')

s3_client = boto3.client('s3')

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

def lambda_handler(event, context):
    """
    Generate daily order report
    """
    conn = None  # FIX: inisialisasi di luar try agar finally bisa close
    try:
        report_date = datetime.now().date()
        start_date = report_date - timedelta(days=1)
        
        conn = get_db_connection()
        
        # Daily orders summary
        # FIX #1: order_date → created_at (sesuai schema di init_database)
        query = """
            SELECT 
                o.status,
                COUNT(*) as order_count,
                SUM(o.total_amount) as total_revenue
            FROM orders o
            WHERE DATE(o.created_at) = %s
            GROUP BY o.status
        """
        
        df_summary = pd.read_sql_query(query, conn, params=(start_date,))
        
        # Top products
        # FIX #2: order_date → created_at
        query = """
            SELECT 
                i.product_name,
                SUM(oi.quantity) as total_quantity,
                SUM(oi.quantity * oi.price) as total_revenue
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            JOIN inventory i ON oi.product_id = i.product_id
            WHERE DATE(o.created_at) = %s
            GROUP BY i.product_name
            ORDER BY total_revenue DESC
            LIMIT 10
        """
        
        df_products = pd.read_sql_query(query, conn, params=(start_date,))
        
        # Inventory status
        query = """
            SELECT 
                product_name,
                stock_quantity,
                CASE 
                    WHEN stock_quantity < 10 THEN 'Critical'
                    WHEN stock_quantity < 50 THEN 'Low'
                    ELSE 'Normal'
                END as stock_status
            FROM inventory
            ORDER BY stock_quantity ASC
            LIMIT 20
        """
        
        df_inventory = pd.read_sql_query(query, conn)
        
        # FIX: pindah conn.close() ke finally block
        
        # Handle empty dataframes (no orders yesterday — normal case)
        if df_summary.empty:
            df_summary = pd.DataFrame(columns=['status', 'order_count', 'total_revenue'])
        if df_products.empty:
            df_products = pd.DataFrame(columns=['product_name', 'total_quantity', 'total_revenue'])
        
        # Create Excel report
        output = BytesIO()
        with pd.ExcelWriter(output, engine='openpyxl') as writer:
            df_summary.to_excel(writer, sheet_name='Daily Summary', index=False)
            df_products.to_excel(writer, sheet_name='Top Products', index=False)
            df_inventory.to_excel(writer, sheet_name='Inventory Status', index=False)
        
        output.seek(0)
        
        # Upload to S3
        report_key = f"reports/daily-report-{start_date}.xlsx"
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=report_key,
            Body=output.getvalue(),
            ContentType='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
        
        # Create JSON summary
        total_revenue = float(df_summary['total_revenue'].sum()) if not df_summary.empty else 0.0
        total_orders  = int(df_summary['order_count'].sum())     if not df_summary.empty else 0

        summary = {
            'report_date': str(start_date),
            'total_orders': total_orders,
            'total_revenue': total_revenue,
            'orders_by_status': df_summary.to_dict('records'),
            'top_products': df_products.head(5).to_dict('records'),
            'low_stock_items': df_inventory[df_inventory['stock_status'] != 'Normal'].to_dict('records')
        }
        
        # Save JSON summary
        summary_key = f"reports/daily-summary-{start_date}.json"
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=summary_key,
            Body=json.dumps(summary, indent=2),
            ContentType='application/json'
        )
        
        return {
            'status': 'success',
            'message': 'Report generated successfully',
            'report_date': str(start_date),
            'report_location': f"s3://{S3_BUCKET}/{report_key}",
            'summary': summary
        }
        
    except Exception as e:
        print(f"Error generating report: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'status': 'error',
            'message': f'Report generation failed: {str(e)}'
        }
    
    finally:
        # FIX: pastikan koneksi selalu ditutup
        if conn:
            conn.close()
