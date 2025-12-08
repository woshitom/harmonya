"""
PayPal Webhook Handler for Firebase Cloud Functions
This file provides a structure for handling PayPal webhooks

To set up PayPal webhooks:
1. Go to https://developer.paypal.com/
2. Navigate to your app settings
3. Add webhook URL: https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/paypal_webhook
4. Subscribe to events: PAYMENT.CAPTURE.COMPLETED, PAYMENT.CAPTURE.DENIED, etc.

Note: This is a basic structure. You'll need to:
- Verify webhook signatures for security
- Handle different event types
- Update Firestore accordingly
"""

import os
import json
from typing import Any

import firebase_admin
from firebase_admin import firestore
from firebase_functions import https_fn
import resend

# Initialize Firebase Admin (if not already initialized)
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app()

db = firestore.client()

# PayPal Webhook Secret (get from PayPal Developer Dashboard)
PAYPAL_WEBHOOK_SECRET = os.environ.get("PAYPAL_WEBHOOK_SECRET", "")


def verify_paypal_webhook(headers: dict, body: str, webhook_id: str) -> bool:
    """
    Verify PayPal webhook signature
    This is a placeholder - implement actual signature verification
    See: https://developer.paypal.com/docs/api-basics/notifications/webhooks/notification-messages/
    """
    # TODO: Implement PayPal webhook signature verification
    # This is critical for security in production
    return True


@https_fn.on_request(
    cors=True,  # PayPal webhooks are server-to-server, so CORS isn't strictly needed
    # But we enable it for flexibility. For webhooks, PayPal doesn't check CORS headers.
    region="europe-west9"
)
def paypal_webhook(req: https_fn.Request) -> https_fn.Response:
    """
    Handle PayPal webhook events
    This endpoint receives POST requests from PayPal when payment events occur
    """
    try:
        # Get webhook event data
        event_data = req.get_json(silent=True)
        
        if not event_data:
            return https_fn.Response(
                json.dumps({"error": "Invalid request body"}),
                status=400,
                mimetype="application/json"
            )
        
        # Extract event type and resource
        event_type = event_data.get("event_type", "")
        resource = event_data.get("resource", {})
        
        # Verify webhook signature (in production, always verify!)
        # webhook_id = req.headers.get("PAYPAL-TRANSMISSION-ID", "")
        # if not verify_paypal_webhook(req.headers, req.get_data(as_text=True), webhook_id):
        #     return https_fn.Response(
        #         json.dumps({"error": "Invalid signature"}),
        #         status=401,
        #         mimetype="application/json"
        #     )
        
        print(f"Received PayPal webhook event: {event_type}")
        
        # Handle different event types
        if event_type == "PAYMENT.CAPTURE.COMPLETED":
            # Payment was successfully captured
            order_id = resource.get("id", "")
            
            # Extract custom_id (voucher ID) from purchase_units
            # PayPal webhook structure: resource.purchase_units[0].custom_id
            purchase_units = resource.get("purchase_units", [])
            custom_id = ""
            if purchase_units and len(purchase_units) > 0:
                custom_id = purchase_units[0].get("custom_id", "")
            
            # Fallback: try direct custom_id in resource (some PayPal versions)
            if not custom_id:
                custom_id = resource.get("custom_id", "")
            
            if custom_id:
                # Update voucher status in Firestore
                voucher_ref = db.collection("gift_vouchers").document(custom_id)
                voucher_ref.update({
                    "status": "paid",
                    "paidAt": firestore.SERVER_TIMESTAMP,
                    "paypalOrderId": order_id,
                })
                print(f"Updated voucher {custom_id} to paid status")
            else:
                print(f"Warning: No custom_id found in webhook for order {order_id}")
            
            return https_fn.Response(
                json.dumps({"status": "success"}),
                status=200,
                mimetype="application/json"
            )
        
        elif event_type == "PAYMENT.CAPTURE.DENIED":
            # Payment was denied
            order_id = resource.get("id", "")
            
            # Extract custom_id from purchase_units
            purchase_units = resource.get("purchase_units", [])
            custom_id = ""
            if purchase_units and len(purchase_units) > 0:
                custom_id = purchase_units[0].get("custom_id", "")
            if not custom_id:
                custom_id = resource.get("custom_id", "")
            
            if custom_id:
                # Optionally update voucher status or send notification
                print(f"Payment denied for voucher {custom_id}")
            
            return https_fn.Response(
                json.dumps({"status": "received"}),
                status=200,
                mimetype="application/json"
            )
        
        elif event_type == "PAYMENT.CAPTURE.REFUNDED":
            # Payment was refunded
            order_id = resource.get("id", "")
            
            # Extract custom_id from purchase_units
            purchase_units = resource.get("purchase_units", [])
            custom_id = ""
            if purchase_units and len(purchase_units) > 0:
                custom_id = purchase_units[0].get("custom_id", "")
            if not custom_id:
                custom_id = resource.get("custom_id", "")
            
            if custom_id:
                # Update voucher status
                voucher_ref = db.collection("gift_vouchers").document(custom_id)
                voucher_ref.update({
                    "status": "refunded",
                })
                print(f"Updated voucher {custom_id} to refunded status")
            
            return https_fn.Response(
                json.dumps({"status": "success"}),
                status=200,
                mimetype="application/json"
            )
        
        else:
            # Unknown event type - log but don't fail
            print(f"Unhandled event type: {event_type}")
            return https_fn.Response(
                json.dumps({"status": "received"}),
                status=200,
                mimetype="application/json"
            )
    
    except Exception as e:
        print(f"Error processing PayPal webhook: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            mimetype="application/json"
        )

