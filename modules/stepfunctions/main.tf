data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ─────────────────────────────────────────────
# STATE MACHINE: lks-stepfunctions-order-workflow
#
# FIX #3: Hapus step ValidateOrder yang memanggil lks-lambda-order-management
# dengan payload { action: "validate" } — lambda tersebut adalah API handler
# berbasis httpMethod + resource (API Gateway format), tidak punya route untuk
# "action=validate", sehingga setiap eksekusi workflow GAGAL di step pertama.
#
# Solusi: ValidateOrder diganti menjadi Pass state (validasi sudah dilakukan
# di create_order sebelum SFN dipanggil). Workflow langsung ke ProcessPayment.
# ─────────────────────────────────────────────
resource "aws_sfn_state_machine" "order_workflow" {
  name     = "lks-stepfunctions-order-workflow"
  role_arn = data.aws_iam_role.lab_role.arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "LKS Order Processing Workflow"
    StartAt = "ValidateOrder"
    States = {

      # ── Step 1: ValidateOrder — FIXED: Pass state (bukan Lambda call)
      # Validasi input sudah dilakukan oleh lks-lambda-order-management
      # sebelum StartExecution dipanggil. Tidak perlu memanggil Lambda lagi.
      ValidateOrder = {
        Type    = "Pass"
        Comment = "Input validated by order_management Lambda before SFN start"
        Next    = "ProcessPayment"
      }

      # ── Step 2: Process Payment ─────────────
      ProcessPayment = {
        Type     = "Task"
        Resource = var.lambda_process_payment_arn
        Parameters = {
          "order_id.$"     = "$.orderId"
          "total_amount.$" = "$.totalAmount"
          "customer_id.$"  = "$.customerId"
        }
        ResultPath = "$.paymentResult"
        Next       = "PaymentChoice"
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException"]
          IntervalSeconds = 2
          MaxAttempts     = 2
          BackoffRate     = 2
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "PaymentFailed"
          ResultPath  = "$.error"
        }]
      }

      # ── Step 3: Payment Choice ──────────────
      PaymentChoice = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.paymentResult.paymentStatus"
            StringEquals = "success"
            Next         = "UpdateInventory"
          },
          {
            Variable     = "$.paymentResult.paymentStatus"
            StringEquals = "failed"
            Next         = "PaymentFailed"
          }
        ]
        Default = "PaymentFailed"
      }

      # ── Step 4a: Payment Failed ─────────────
      PaymentFailed = {
        Type     = "Task"
        Resource = var.lambda_send_notification_arn
        Parameters = {
          "order_id.$"        = "$.orderId"
          "notification_type" = "payment_failed"
          "amount.$"          = "$.totalAmount"
          "error_message"     = "Payment processing failed"
        }
        ResultPath = "$.notifyResult"
        Next       = "OrderFailed"
      }

      # ── Step 4b: Update Inventory ───────────
      UpdateInventory = {
        Type     = "Task"
        Resource = var.lambda_update_inventory_arn
        Parameters = {
          "orderId.$"        = "$.orderId"
          "customerId.$"     = "$.customerId"
          "items.$"          = "$.items"
          "transaction_id.$" = "$.paymentResult.transaction_id"
        }
        ResultPath = "$.inventoryResult"
        Next       = "InventoryChoice"
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException"]
          IntervalSeconds = 2
          MaxAttempts     = 2
          BackoffRate     = 2
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "InventoryFailed"
          ResultPath  = "$.error"
        }]
      }

      # ── Step 5: Inventory Choice ─────────────
      InventoryChoice = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.inventoryResult.inventoryStatus"
            StringEquals = "success"
            Next         = "SendConfirmation"
          },
          {
            Variable     = "$.inventoryResult.inventoryStatus"
            StringEquals = "failed"
            Next         = "InventoryFailed"
          }
        ]
        Default = "InventoryFailed"
      }

      # ── Step 5a: Inventory Failed ────────────
      InventoryFailed = {
        Type     = "Task"
        Resource = var.lambda_send_notification_arn
        Parameters = {
          "order_id.$"        = "$.orderId"
          "notification_type" = "system_error"
          "error_message"     = "Inventory update failed - insufficient stock"
        }
        ResultPath = "$.notifyResult"
        Next       = "OrderFailed"
      }

      # ── Step 6: Send Confirmation ───────────
      SendConfirmation = {
        Type     = "Task"
        Resource = var.lambda_send_notification_arn
        Parameters = {
          "order_id.$"        = "$.orderId"
          "notification_type" = "order_confirmation"
          "amount.$"          = "$.totalAmount"
          "transaction_id.$"  = "$.paymentResult.transaction_id"
        }
        ResultPath = "$.confirmResult"
        Next       = "OrderCompleted"
      }

      # ── Step 7: Order Completed ─────────────
      OrderCompleted = {
        Type = "Succeed"
      }

      # ── Step 7b: Order Failed ───────────────
      OrderFailed = {
        Type  = "Fail"
        Error = "OrderProcessingFailed"
        Cause = "Order could not be completed - check execution events for details"
      }
    }
  })

  tags = { Name = "lks-stepfunctions-order-workflow" }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "stepfunctions" {
  name              = "/aws/states/lks-stepfunctions-order-workflow"
  retention_in_days = 7
}
