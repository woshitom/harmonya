"""
Firebase Cloud Function pour envoyer des emails lors de nouvelles réservations
Implémentation Python - Firebase Functions 2nd Gen

Installation:
1. pip install -r requirements.txt
2. firebase functions:config:set resend.api_key="votre-api-key"
3. firebase deploy --only functions
"""

import os
import json
import time
from datetime import datetime
from typing import Any

import firebase_admin
from firebase_admin import firestore, initialize_app
from firebase_functions import firestore_fn, https_fn
import resend
import json

# Initialiser Firebase Admin
initialize_app()

# Configuration
# IMPORTANT: Never hardcode API keys or secrets in source code!
# For Firebase Functions 2nd Gen Python, use secrets (firebase functions:secrets:set)
# Secrets are accessed via os.environ when declared in function decorators
RESEND_API_KEY = os.environ.get("RESEND_API_KEY", "")
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "contact@harmonyamassage.fr")
# Note: Resend doesn't allow free domains like gmail.com
# Use onboarding@resend.dev for testing, or verify your own domain for production
FROM_EMAIL = os.environ.get("FROM_EMAIL", "Harmonya <contact@harmonyamassage.fr>")

# Helper function to get Resend API key from secrets or config
def get_resend_api_key() -> str:
    """Get Resend API key from environment variables (secrets)"""
    # Try secret first (Firebase Functions 2nd Gen)
    api_key = os.environ.get("RESEND_API_KEY", "")
    if api_key:
        # Strip whitespace (including newlines) that might have been included when setting the secret
        return api_key.strip()
    # Fallback: try to get from Firebase Functions config (for backward compatibility)
    # Note: This might not work in 2nd Gen, but kept for compatibility
    try:
        import google.cloud.runtimeconfig
        # This is a fallback - secrets are preferred
        pass
    except:
        pass
    return ""


def get_service_name_and_label(booking: dict) -> tuple[str, str]:
    """
    Extrait le nom du service et le label approprié depuis les données de réservation
    Retourne: (service_name, label)
    """
    massage_type = booking.get("massageType", "")
    service_type = booking.get("serviceType", "massage")  # Default to 'massage'
    
    # Déterminer le label
    label = "Type de soins:" if service_type == "soins" else "Type de massage:"
    
    # Si massageType est vide, retourner une valeur par défaut
    if not massage_type:
        return ("Non spécifié", label)
    
    # Extraire l'ID du service depuis le format "serviceId_duration"
    # Exemple: "cocooning_60" -> service_id = "cocooning"
    parts = massage_type.split('_')
    service_id = parts[0] if parts else massage_type
    
    # Récupérer le nom du service depuis Firestore
    try:
        db = firestore.client()
        collection_name = "treatments" if service_type == "soins" else "massages"
        service_doc = db.collection(collection_name).document(service_id).get()
        
        if service_doc.exists:
            service_data = service_doc.to_dict()
            service_name = service_data.get("name", service_id)
            return (service_name, label)
        else:
            # Si le document n'existe pas, retourner l'ID comme fallback
            return (service_id, label)
    except Exception as e:
        print(f"Erreur lors de la récupération du nom du service: {str(e)}")
        # En cas d'erreur, retourner l'ID comme fallback
        return (service_id, label)


def parse_firestore_date(date_value) -> datetime | None:
    """Parse une date Firestore dans différents formats"""
    if date_value is None:
        return None
    
    # Format dict Firestore Timestamp (le plus commun)
    if isinstance(date_value, dict):
        seconds = date_value.get("_seconds") or date_value.get("seconds")
        if seconds:
            nanoseconds = date_value.get("_nanoseconds") or date_value.get("nanoseconds", 0)
            return datetime.fromtimestamp(seconds + nanoseconds / 1e9)
        # Essayer aussi avec d'autres clés possibles
        if "value" in date_value:
            return parse_firestore_date(date_value["value"])
    
    # Objet Timestamp Firestore (avec méthode to_datetime)
    if hasattr(date_value, 'to_datetime'):
        try:
            return date_value.to_datetime()
        except:
            pass
    
    # Objet Timestamp Firestore (avec méthode timestamp)
    if hasattr(date_value, 'timestamp'):
        try:
            return datetime.fromtimestamp(date_value.timestamp())
        except:
            pass
    
    # String ISO format
    if isinstance(date_value, str):
        try:
            return datetime.fromisoformat(date_value.replace('Z', '+00:00'))
        except:
            try:
                return datetime.strptime(date_value, '%Y-%m-%dT%H:%M:%S.%f')
            except:
                try:
                    return datetime.strptime(date_value, '%Y-%m-%d %H:%M:%S')
                except:
                    pass
    
    # Déjà un datetime
    if isinstance(date_value, datetime):
        return date_value
    
    return None


def format_date_french(timestamp) -> str:
    """Formate une date en français"""
    date = parse_firestore_date(timestamp)
    
    if date is None:
        return "Date non spécifiée"
    
    # Format français
    days = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
    months = [
        "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    ]
    
    weekday = days[date.weekday()]
    month = months[date.month - 1]
    
    return f"{weekday} {date.day} {month} {date.year}"


def get_html_template_admin(booking: dict, booking_id: str, date_formatted: str) -> str:
    """Génère le template HTML pour l'email admin"""
    notes_html = ""
    if booking.get("notes"):
        notes_html = f"""
                <div class="info-row">
                  <span class="label">Notes:</span> {booking.get("notes")}
                </div>
        """
    
    # Home massage information
    location_html = ""
    is_at_home = booking.get("isAtHome", False)
    if is_at_home:
        home_address = booking.get("homeAddress", "")
        location_html = f"""
      <div class="info-row">
        <span class="label">Lieu:</span> À domicile
      </div>
      <div class="info-row">
        <span class="label">Adresse:</span> {home_address}
      </div>
        """
    else:
        location_html = """
      <div class="info-row">
        <span class="label">Lieu:</span> Au cabinet
      </div>
        """
    
    # Get service name and label
    service_name, service_label = get_service_name_and_label(booking)
    
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
    .header {{ background-color: #6B4423; color: white; padding: 20px; text-align: center; }}
    .content {{ background-color: #F5F1E8; padding: 20px; }}
    .info-row {{ margin: 10px 0; }}
    .label {{ font-weight: bold; color: #6B4423; }}
    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Nouvelle Réservation</h1>
    </div>
    <div class="content">
      <p>Une nouvelle réservation a été reçue :</p>
      <div class="info-row">
        <span class="label">Nom:</span> {booking.get("name", "")}
      </div>
      <div class="info-row">
        <span class="label">Email:</span> {booking.get("email", "")}
      </div>
      <div class="info-row">
        <span class="label">Téléphone:</span> {booking.get("phone", "")}
      </div>
      <div class="info-row">
        <span class="label">Date:</span> {date_formatted}
      </div>
      <div class="info-row">
        <span class="label">Heure:</span> {booking.get("time", "")}
      </div>
      <div class="info-row">
        <span class="label">{service_label}</span> {service_name}
      </div>
      {location_html}
      {notes_html}
      <div class="info-row">
        <span class="label">Statut:</span> {booking.get("status", "en_attente")}
      </div>
      <div class="info-row">
        <span class="label">ID Réservation:</span> {booking_id}
      </div>
    </div>
    <div class="footer">
      <p>Harmonya - Massage & Bien-être</p>
      <p>1 A rue de la poste 67400 ILLKIRCH GRAFFENSTADEN</p>
      <p><a href="https://harmonyamassage.fr" style="color: #6B4423; text-decoration: none;">harmonyamassage.fr</a></p>
    </div>
  </div>
</body>
</html>
"""


def get_html_template_client(booking: dict, date_formatted: str) -> str:
    """Génère le template HTML pour l'email client"""
    # Home massage information
    location_html = ""
    is_at_home = booking.get("isAtHome", False)
    if is_at_home:
        home_address = booking.get("homeAddress", "")
        location_html = f"""
      <div class="info-row">
        <span class="label">Lieu:</span> À domicile
      </div>
      <div class="info-row">
        <span class="label">Adresse:</span> {home_address}
      </div>
        """
    else:
        location_html = """
      <div class="info-row">
        <span class="label">Lieu:</span> Au cabinet
      </div>
        """
    
    # Get service name and label
    service_name, service_label = get_service_name_and_label(booking)
    
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
    .header {{ background-color: #6B4423; color: white; padding: 20px; text-align: center; }}
    .content {{ background-color: #F5F1E8; padding: 20px; }}
    .info-row {{ margin: 10px 0; }}
    .label {{ font-weight: bold; color: #6B4423; }}
    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Merci pour votre réservation !</h1>
    </div>
    <div class="content">
      <p>Bonjour {booking.get("name", "")},</p>
      <p>Nous avons bien reçu votre demande de réservation :</p>
      <div class="info-row">
        <span class="label">Date:</span> {date_formatted}
      </div>
      <div class="info-row">
        <span class="label">Heure:</span> {booking.get("time", "")}
      </div>
      <div class="info-row">
        <span class="label">{service_label}</span> {service_name}
      </div>
      {location_html}
      <p style="margin-top: 20px;">
        Nous vous contacterons bientôt par téléphone ou email pour confirmer votre rendez-vous.
      </p>
      <p>Cordialement,<br><strong>L'équipe Harmonya</strong></p>
    </div>
    <div class="footer">
      <p><strong>Harmonya</strong></p>
      <p>1 A rue de la poste<br>67400 ILLKIRCH GRAFFENSTADEN</p>
      <p>Téléphone: 06 26 14 25 89</p>
      <p><a href="https://harmonyamassage.fr" style="color: #6B4423; text-decoration: none;">harmonyamassage.fr</a></p>
    </div>
  </div>
</body>
</html>
"""


def get_html_template_confirmed(booking: dict, date_formatted: str) -> str:
    """Génère le template HTML pour l'email de confirmation"""
    # Home massage information
    location_html = ""
    is_at_home = booking.get("isAtHome", False)
    if is_at_home:
        home_address = booking.get("homeAddress", "")
        location_html = f"""
      <div class="info-row">
        <span class="label">Lieu:</span> À domicile
      </div>
      <div class="info-row">
        <span class="label">Adresse:</span> {home_address}
      </div>
        """
    else:
        location_html = """
      <div class="info-row">
        <span class="label">Lieu:</span> Au cabinet
      </div>
        """
    
    # Get service name and label
    service_name, service_label = get_service_name_and_label(booking)
    
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
    .header {{ background-color: #28a745; color: white; padding: 20px; text-align: center; }}
    .content {{ background-color: #F5F1E8; padding: 20px; }}
    .info-row {{ margin: 10px 0; }}
    .label {{ font-weight: bold; color: #6B4423; }}
    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
    .success-box {{ background-color: #d4edda; border: 1px solid #c3e6cb; border-radius: 5px; padding: 15px; margin: 20px 0; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✓ Réservation Confirmée</h1>
    </div>
    <div class="content">
      <p>Bonjour {booking.get("name", "")},</p>
      <div class="success-box">
        <p style="margin: 0; font-weight: bold; color: #155724;">
          Votre réservation a été confirmée avec succès !
        </p>
      </div>
      <p>Voici les détails de votre rendez-vous :</p>
      <div class="info-row">
        <span class="label">Date:</span> {date_formatted}
      </div>
      <div class="info-row">
        <span class="label">Heure:</span> {booking.get("time", "")}
      </div>
      <div class="info-row">
        <span class="label">{service_label}</span> {service_name}
      </div>
      {location_html}
      <p style="margin-top: 20px;">
        {'Nous nous déplacerons à votre domicile pour ce service.' if is_at_home else 'Nous avons hâte de vous accueillir à Harmonya.'} Si vous avez des questions ou souhaitez modifier votre réservation, n'hésitez pas à nous contacter.
      </p>
      <p>Cordialement,<br><strong>L'équipe Harmonya</strong></p>
    </div>
    <div class="footer">
      <p><strong>Harmonya</strong></p>
      <p>1 A rue de la poste<br>67400 ILLKIRCH GRAFFENSTADEN</p>
      <p>Téléphone: 06 26 14 25 89</p>
      <p><a href="https://harmonyamassage.fr" style="color: #6B4423; text-decoration: none;">harmonyamassage.fr</a></p>
    </div>
  </div>
</body>
</html>
"""


def get_html_template_cancelled(booking: dict, date_formatted: str) -> str:
    """Génère le template HTML pour l'email d'annulation"""
    # Home massage information
    location_html = ""
    is_at_home = booking.get("isAtHome", False)
    if is_at_home:
        home_address = booking.get("homeAddress", "")
        location_html = f"""
      <div class="info-row">
        <span class="label">Lieu:</span> À domicile
      </div>
      <div class="info-row">
        <span class="label">Adresse:</span> {home_address}
      </div>
        """
    else:
        location_html = """
      <div class="info-row">
        <span class="label">Lieu:</span> Au cabinet
      </div>
        """
    
    # Get service name and label
    service_name, service_label = get_service_name_and_label(booking)
    
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
    .header {{ background-color: #dc3545; color: white; padding: 20px; text-align: center; }}
    .content {{ background-color: #F5F1E8; padding: 20px; }}
    .info-row {{ margin: 10px 0; }}
    .label {{ font-weight: bold; color: #6B4423; }}
    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
    .info-box {{ background-color: #f8d7da; border: 1px solid #f5c6cb; border-radius: 5px; padding: 15px; margin: 20px 0; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Réservation Annulée</h1>
    </div>
    <div class="content">
      <p>Bonjour {booking.get("name", "")},</p>
      <div class="info-box">
        <p style="margin: 0; color: #721c24;">
          Nous sommes désolés de vous informer que votre réservation a été annulée.
        </p>
      </div>
      <p>Détails de la réservation annulée :</p>
      <div class="info-row">
        <span class="label">Date:</span> {date_formatted}
      </div>
      <div class="info-row">
        <span class="label">Heure:</span> {booking.get("time", "")}
      </div>
      <div class="info-row">
        <span class="label">{service_label}</span> {service_name}
      </div>
      {location_html}
      <p style="margin-top: 20px;">
        Si vous souhaitez réserver un autre créneau, n'hésitez pas à nous contacter. Nous serons ravis de vous aider à trouver un nouveau rendez-vous.
      </p>
      <p>Cordialement,<br><strong>L'équipe Harmonya</strong></p>
    </div>
    <div class="footer">
      <p><strong>Harmonya</strong></p>
      <p>1 A rue de la poste<br>67400 ILLKIRCH GRAFFENSTADEN</p>
      <p>Téléphone: 06 26 14 25 89</p>
      <p><a href="https://harmonyamassage.fr" style="color: #6B4423; text-decoration: none;">harmonyamassage.fr</a></p>
    </div>
  </div>
</body>
</html>
"""


def create_or_update_customer(booking: dict, booking_id: str) -> None:
    """
    Crée ou met à jour un document client dans la collection "customers"
    basé sur les informations de la réservation
    """
    try:
        customer_email = booking.get("email")
        customer_name = booking.get("name", "")
        customer_phone = booking.get("phone", "")
        massage_type = booking.get("massageType", "")
        service_type = booking.get("serviceType", "")  # 'massage' or 'soins'
        service_name = booking.get("serviceName", "")  # Service name from booking
        
        if not customer_email:
            print(f"Pas d'email trouvé dans la réservation {booking_id}, impossible de créer/mettre à jour le client")
            return
        
        # Extraire l'ID du service depuis le format "serviceId_duration"
        # Exemple: "facial_60" -> service_id = "facial"
        service_id = ""
        if massage_type and massage_type.strip():
            parts = massage_type.split('_')
            service_id = parts[0] if parts else massage_type
        
        # Si serviceName n'est pas dans le booking, le récupérer depuis Firestore
        if not service_name and service_id:
            try:
                db = firestore.client()
                collection_name = "treatments" if service_type == "soins" else "massages"
                service_doc = db.collection(collection_name).document(service_id).get()
                if service_doc.exists:
                    service_data = service_doc.to_dict()
                    service_name = service_data.get("name", service_id)
                else:
                    service_name = service_id  # Fallback to ID if document not found
            except Exception as e:
                print(f"Erreur lors de la récupération du nom du service: {str(e)}")
                service_name = service_id  # Fallback to ID on error
        
        db = firestore.client()
        customer_ref = db.collection("customers").document(customer_email)
        customer_doc = customer_ref.get()
        
        if customer_doc.exists:
            # Le document existe, mettre à jour
            customer_data = customer_doc.to_dict()
            massage_types = customer_data.get("massageTypes", [])
            treatment_types = customer_data.get("treatmentTypes", [])
            massage_types_names = customer_data.get("massageTypesNames", [])
            treatment_types_names = customer_data.get("treatmentTypesNames", [])
            
            # Déterminer si c'est un massage ou un traitement
            is_treatment = service_type == "soins"
            
            # Ajouter le type de service (ID et nom) dans les bons tableaux s'il n'est pas vide
            if service_id:
                if is_treatment:
                    # C'est un traitement
                    if service_id not in treatment_types:
                        treatment_types.append(service_id)
                        treatment_types_names.append(service_name if service_name else service_id)
                else:
                    # C'est un massage
                    if service_id not in massage_types:
                        massage_types.append(service_id)
                        massage_types_names.append(service_name if service_name else service_id)
            
            # Mettre à jour le document
            customer_ref.update({
                "name": customer_name,
                "phone": customer_phone,
                "massageTypes": massage_types,
                "treatmentTypes": treatment_types,
                "massageTypesNames": massage_types_names,
                "treatmentTypesNames": treatment_types_names,
            })
            print(f"Document client mis à jour pour {customer_email}")
        else:
            # Le document n'existe pas, le créer
            # Déterminer si c'est un massage ou un traitement
            is_treatment = service_type == "soins"
            
            # Créer les tableaux appropriés
            massage_types_list = []
            treatment_types_list = []
            massage_types_names_list = []
            treatment_types_names_list = []
            
            if service_id:
                if is_treatment:
                    treatment_types_list = [service_id]
                    treatment_types_names_list = [service_name if service_name else service_id]
                else:
                    massage_types_list = [service_id]
                    massage_types_names_list = [service_name if service_name else service_id]
            
            customer_ref.set({
                "email": customer_email,
                "name": customer_name,
                "phone": customer_phone,
                "massageTypes": massage_types_list,
                "treatmentTypes": treatment_types_list,
                "massageTypesNames": massage_types_names_list,
                "treatmentTypesNames": treatment_types_names_list,
                "added_at": firestore.SERVER_TIMESTAMP,
            })
            print(f"Nouveau document client créé pour {customer_email}")
    except Exception as e:
        print(f"Erreur lors de la création/mise à jour du document client: {str(e)}")
        import traceback
        traceback.print_exc()


@firestore_fn.on_document_created(
    document="bookings/{bookingId}",
    region="europe-west9",
    secrets=["RESEND_API_KEY"]
)
def send_booking_email(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Fonction déclenchée automatiquement lorsqu'une nouvelle réservation est créée
    Format: Firebase Functions 2nd gen Python
    """
    try:
        # Récupérer les données de la réservation depuis l'événement Firestore
        snapshot = event.data
        if snapshot is None:
            print("Aucune donnée dans l'événement")
            return
        
        # Récupérer les données du document
        booking = snapshot.to_dict()
        booking_id = snapshot.id
        
        if booking is None:
            print(f"Aucune donnée trouvée pour la réservation {booking_id}")
            return
        
        # Formater la date en français
        date_timestamp = booking.get("date")
        if date_timestamp:
            # Convertir Timestamp Firestore en datetime si nécessaire
            if hasattr(date_timestamp, 'to_datetime'):
                date_timestamp = date_timestamp.to_datetime()
            elif isinstance(date_timestamp, dict):
                # Format Firestore Timestamp
                seconds = date_timestamp.get("_seconds") or date_timestamp.get("seconds", 0)
                nanoseconds = date_timestamp.get("_nanoseconds") or date_timestamp.get("nanoseconds", 0)
                date_timestamp = datetime.fromtimestamp(seconds + nanoseconds / 1e9)
            date_formatted = format_date_french(date_timestamp)
        else:
            date_formatted = "Date non spécifiée"
        
        # Vérifier que Resend API Key est configurée
        api_key = get_resend_api_key()
        if not api_key:
            print(f"ERREUR: RESEND_API_KEY non configurée pour la réservation {booking_id}")
            return
        resend.api_key = api_key
        
        # Vérifier le statut de la réservation
        booking_status = booking.get("status", "en_attente")
        
        # Si la réservation est confirmée (créée par l'admin), envoyer uniquement la confirmation au client
        if booking_status == "confirmed":
            print(f"Réservation {booking_id} créée avec statut 'confirmed' - Envoi uniquement de la confirmation au client")
            
            # Créer ou mettre à jour le document client dans la collection "customers"
            create_or_update_customer(booking, booking_id)
            
            client_email = booking.get("email")
            if client_email:
                try:
                    client_html = get_html_template_confirmed(booking, date_formatted)
                    
                    result = resend.Emails.send({
                        "from": FROM_EMAIL,
                        "to": client_email,
                        "subject": "Confirmation de votre réservation - Harmonya",
                        "html": client_html,
                    })
                    print(f"Email de confirmation envoyé avec succès au client pour la réservation {booking_id}: {result}")
                except Exception as e:
                    print(f"Erreur lors de l'envoi de l'email de confirmation au client: {str(e)}")
                    import traceback
                    traceback.print_exc()
            else:
                print(f"Pas d'email client trouvé pour la réservation {booking_id}")
            return
        
        # Pour les réservations en attente (créées par le client), envoyer à l'admin et au client
        # Envoyer l'email à l'administrateur
        try:
            admin_html = get_html_template_admin(booking, booking_id, date_formatted)
            
            result = resend.Emails.send({
                "from": FROM_EMAIL,
                "to": ADMIN_EMAIL,
                "subject": f"Nouvelle réservation - {booking.get('name', '')}",
                "html": admin_html,
            })
            print(f"Email admin envoyé avec succès pour la réservation {booking_id}: {result}")
        except Exception as e:
            print(f"Erreur lors de l'envoi de l'email admin: {str(e)}")
            import traceback
            traceback.print_exc()
        
        # Envoyer l'email de confirmation au client
        client_email = booking.get("email")
        if client_email:
            try:
                client_html = get_html_template_client(booking, date_formatted)
                
                result = resend.Emails.send({
                    "from": FROM_EMAIL,
                    "to": client_email,
                    "subject": "Confirmation de votre réservation - Harmonya",
                    "html": client_html,
                })
                print(f"Email client envoyé avec succès pour la réservation {booking_id}: {result}")
            except Exception as e:
                print(f"Erreur lors de l'envoi de l'email client: {str(e)}")
                import traceback
                traceback.print_exc()
        else:
            print(f"Pas d'email client trouvé pour la réservation {booking_id}")
            
    except Exception as e:
        print(f"Erreur générale dans send_booking_email: {str(e)}")
        import traceback
        traceback.print_exc()


@firestore_fn.on_document_updated(
    document="bookings/{bookingId}",
    region="europe-west9",
    secrets=["RESEND_API_KEY"]
)
def send_booking_status_email(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Fonction déclenchée automatiquement lorsqu'une réservation est mise à jour
    Envoie un email au client si le statut change à 'confirmed' ou 'cancelled'
    """
    try:
        # Récupérer les données avant et après la mise à jour
        before_snapshot = event.data.before
        after_snapshot = event.data.after
        
        if before_snapshot is None or after_snapshot is None:
            print("Données manquantes dans l'événement de mise à jour")
            return
        
        booking_before = before_snapshot.to_dict()
        booking_after = after_snapshot.to_dict()
        booking_id = after_snapshot.id
        
        if booking_before is None or booking_after is None:
            print(f"Aucune donnée trouvée pour la réservation {booking_id}")
            return
        
        # Vérifier si le statut a changé
        old_status = booking_before.get("status", "")
        new_status = booking_after.get("status", "")
        
        # Ne rien faire si le statut n'a pas changé ou si ce n'est pas une confirmation/annulation
        if old_status == new_status:
            print(f"Statut inchangé pour la réservation {booking_id}: {new_status}")
            return
        
        if new_status not in ["confirmed", "cancelled"]:
            print(f"Statut {new_status} ne nécessite pas d'email pour la réservation {booking_id}")
            return
        
        # Formater la date en français
        date_timestamp = booking_after.get("date")
        if date_timestamp:
            # Convertir Timestamp Firestore en datetime si nécessaire
            if hasattr(date_timestamp, 'to_datetime'):
                date_timestamp = date_timestamp.to_datetime()
            elif isinstance(date_timestamp, dict):
                # Format Firestore Timestamp
                seconds = date_timestamp.get("_seconds") or date_timestamp.get("seconds", 0)
                nanoseconds = date_timestamp.get("_nanoseconds") or date_timestamp.get("nanoseconds", 0)
                date_timestamp = datetime.fromtimestamp(seconds + nanoseconds / 1e9)
            date_formatted = format_date_french(date_timestamp)
        else:
            date_formatted = "Date non spécifiée"
        
        # Vérifier que Resend API Key est configurée
        api_key = get_resend_api_key()
        if not api_key:
            print(f"ERREUR: RESEND_API_KEY non configurée pour la réservation {booking_id}")
            return
        resend.api_key = api_key
        
        # Envoyer l'email au client selon le statut
        client_email = booking_after.get("email")
        if not client_email:
            print(f"Pas d'email client trouvé pour la réservation {booking_id}")
            return
        
        try:
            if new_status == "confirmed":
                # Créer ou mettre à jour le document client dans la collection "customers"
                create_or_update_customer(booking_after, booking_id)
                
                # Email de confirmation
                html_content = get_html_template_confirmed(booking_after, date_formatted)
                subject = "Votre réservation est confirmée - Harmonya"
            elif new_status == "cancelled":
                # Email d'annulation
                html_content = get_html_template_cancelled(booking_after, date_formatted)
                subject = "Annulation de votre réservation - Harmonya"
            else:
                return
            
            result = resend.Emails.send({
                "from": FROM_EMAIL,
                "to": client_email,
                "subject": subject,
                "html": html_content,
            })
            print(f"Email de statut ({new_status}) envoyé avec succès pour la réservation {booking_id}: {result}")
            
        except Exception as e:
            print(f"Erreur lors de l'envoi de l'email de statut: {str(e)}")
            import traceback
            traceback.print_exc()
            
    except Exception as e:
        print(f"Erreur générale dans send_booking_status_email: {str(e)}")
        import traceback
        traceback.print_exc()


def get_html_template_review_admin(review: dict, review_id: str, date_formatted: str) -> str:
    """Génère le template HTML pour l'email admin lors d'un nouveau commentaire"""
    # Générer les étoiles pour la note
    rating = review.get("rating", 5)
    stars_html = "".join([
        '<span style="color: #ffc107; font-size: 20px;">★</span>' if i < rating 
        else '<span style="color: #ccc; font-size: 20px;">★</span>' 
        for i in range(5)
    ])
    
    # Nom complet ou anonymisé
    prenom = review.get("prenom", "")
    name = review.get("name", "")
    reviewer_name = f"{prenom} {name}".strip() if prenom or name else "Anonyme"
    
    # Statut d'approbation
    approved_status = "✓ Approuvé" if review.get("approved", False) else "⏳ En attente d'approbation"
    status_color = "#28a745" if review.get("approved", False) else "#ffc107"
    
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
    .header {{ background-color: #6B4423; color: white; padding: 20px; text-align: center; }}
    .content {{ background-color: #F5F1E8; padding: 20px; }}
    .info-row {{ margin: 10px 0; }}
    .label {{ font-weight: bold; color: #6B4423; }}
    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
    .rating {{ margin: 15px 0; text-align: center; }}
    .comment-box {{ background-color: white; border-left: 4px solid #6B4423; padding: 15px; margin: 15px 0; border-radius: 4px; }}
    .status-badge {{ display: inline-block; padding: 5px 15px; border-radius: 20px; color: white; font-weight: bold; background-color: {status_color}; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Nouveau Commentaire</h1>
    </div>
    <div class="content">
      <p>Un nouveau commentaire a été publié :</p>
      <div class="info-row">
        <span class="label">Auteur:</span> {reviewer_name}
      </div>
      <div class="info-row">
        <span class="label">Date:</span> {date_formatted}
      </div>
      <div class="rating">
        <span class="label">Note:</span><br>
        {stars_html} ({rating}/5)
      </div>
      <div class="info-row">
        <span class="label">Statut:</span> 
        <span class="status-badge">{approved_status}</span>
      </div>
      <div class="comment-box">
        <p style="margin: 0; font-style: italic; color: #555;">
          "{review.get("comment", "")}"
        </p>
      </div>
      <div class="info-row">
        <span class="label">ID Commentaire:</span> {review_id}
      </div>
      <p style="margin-top: 20px; padding-top: 15px; border-top: 1px solid #ddd;">
        <strong>Action requise:</strong> Veuillez examiner ce commentaire dans votre panneau d'administration et l'approuver ou le refuser.
      </p>
    </div>
    <div class="footer">
      <p>Harmonya - Massage & Bien-être</p>
      <p>1 A rue de la poste 67400 ILLKIRCH GRAFFENSTADEN</p>
      <p><a href="https://harmonyamassage.fr" style="color: #6B4423; text-decoration: none;">harmonyamassage.fr</a></p>
    </div>
  </div>
</body>
</html>
"""


@firestore_fn.on_document_created(
    document="reviews/{reviewId}",
    region="europe-west9",
    secrets=["RESEND_API_KEY"]
)
def send_review_notification_email(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Fonction déclenchée automatiquement lorsqu'un nouveau commentaire est créé
    Envoie un email à l'administrateur pour notification
    """
    try:
        # Récupérer les données du commentaire
        snapshot = event.data
        if snapshot is None:
            print("Aucune donnée dans l'événement")
            return
        
        review = snapshot.to_dict()
        review_id = snapshot.id
        
        if review is None:
            print(f"Aucune donnée trouvée pour le commentaire {review_id}")
            return
        
        # Formater la date en français
        date_timestamp = review.get("createdAt")
        if date_timestamp:
            # Convertir Timestamp Firestore en datetime si nécessaire
            if hasattr(date_timestamp, 'to_datetime'):
                date_timestamp = date_timestamp.to_datetime()
            elif isinstance(date_timestamp, dict):
                # Format Firestore Timestamp
                seconds = date_timestamp.get("_seconds") or date_timestamp.get("seconds", 0)
                nanoseconds = date_timestamp.get("_nanoseconds") or date_timestamp.get("nanoseconds", 0)
                date_timestamp = datetime.fromtimestamp(seconds + nanoseconds / 1e9)
            date_formatted = format_date_french(date_timestamp)
        else:
            date_formatted = "Date non spécifiée"
        
        # Vérifier que Resend API Key est configurée
        api_key = get_resend_api_key()
        if not api_key:
            print(f"ERREUR: RESEND_API_KEY non configurée pour le commentaire {review_id}")
            return
        resend.api_key = api_key
        
        # Envoyer l'email à l'administrateur
        try:
            admin_html = get_html_template_review_admin(review, review_id, date_formatted)
            
            # Nom de l'auteur pour le sujet
            prenom = review.get("prenom", "")
            name = review.get("name", "")
            reviewer_name = f"{prenom} {name}".strip() if prenom or name else "Anonyme"
            rating = review.get("rating", 5)
            
            result = resend.Emails.send({
                "from": FROM_EMAIL,
                "to": ADMIN_EMAIL,
                "subject": f"Nouveau commentaire - {rating}/5 étoiles de {reviewer_name}",
                "html": admin_html,
            })
            print(f"Email admin envoyé avec succès pour le commentaire {review_id}: {result}")
        except Exception as e:
            print(f"Erreur lors de l'envoi de l'email admin: {str(e)}")
            import traceback
            traceback.print_exc()
            
    except Exception as e:
        print(f"Erreur générale dans send_review_notification_email: {str(e)}")
        import traceback
        traceback.print_exc()


def get_html_template_voucher_purchaser(voucher: dict, voucher_id: str) -> str:
    """Génère le template HTML pour l'email de confirmation à l'acheteur"""
    message_html = ""
    if voucher.get("message"):
        message_html = f"""
      <div class="info-row">
        <span class="label">Message:</span> {voucher.get("message")}
      </div>
        """
    
    expires_date = voucher.get("expiresAt")
    expires_formatted = "Date non spécifiée"
    if expires_date:
        parsed_date = parse_firestore_date(expires_date)
        if parsed_date:
            expires_formatted = format_date_french(parsed_date)
        else:
            # Debug: log the actual format we received
            print(f"DEBUG: Could not parse expiresAt: {type(expires_date)}, value: {expires_date}")
    
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
    .header {{ background-color: #6B4423; color: white; padding: 20px; text-align: center; }}
    .content {{ background-color: #F5F1E8; padding: 20px; }}
    .info-row {{ margin: 10px 0; }}
    .label {{ font-weight: bold; color: #6B4423; }}
    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
    .success-box {{ background-color: #d4edda; border: 1px solid #c3e6cb; border-radius: 5px; padding: 15px; margin: 20px 0; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✓ Bon cadeau acheté avec succès !</h1>
    </div>
    <div class="content">
      <p>Bonjour {voucher.get("purchaserName", "")},</p>
      <div class="success-box">
        <p style="margin: 0; font-weight: bold; color: #155724;">
          Votre bon cadeau a été payé avec succès !
        </p>
      </div>
      <p>Voici les détails de votre achat :</p>
      <div class="info-row">
        <span class="label">Montant:</span> {voucher.get("amount", 0)}€
      </div>
      <div class="info-row">
        <span class="label">Destinataire:</span> {voucher.get("recipientName", "")}
      </div>
      <div class="info-row">
        <span class="label">Email du destinataire:</span> {voucher.get("recipientEmail", "")}
      </div>
      {message_html}
      <div class="info-row">
        <span class="label">Valable jusqu'au:</span> {expires_formatted}
      </div>
      <p style="margin-top: 20px;">
        Le bon cadeau a été envoyé par email à {voucher.get("recipientEmail", "")}.
      </p>
      <p>Cordialement,<br><strong>L'équipe Harmonya</strong></p>
    </div>
    <div class="footer">
      <p><strong>Harmonya</strong></p>
      <p>1 A rue de la poste<br>67400 ILLKIRCH GRAFFENSTADEN</p>
      <p>Téléphone: 06 26 14 25 89</p>
      <p><a href="https://harmonyamassage.fr" style="color: #6B4423; text-decoration: none;">harmonyamassage.fr</a></p>
    </div>
  </div>
</body>
</html>
"""


def get_html_template_voucher_recipient(voucher: dict, voucher_id: str) -> str:
    """Génère le template HTML pour l'email envoyé au destinataire du bon cadeau"""
    message_html = ""
    if voucher.get("message"):
        message_html = f"""
      <div class="info-row" style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; font-style: italic; color: #856404;">
          "{voucher.get("message")}"
        </p>
        <p style="margin: 10px 0 0 0; font-size: 12px; color: #856404;">
          - {voucher.get("purchaserName", "Quelqu'un qui vous aime")}
        </p>
      </div>
        """
    
    expires_date = voucher.get("expiresAt")
    expires_formatted = "Date non spécifiée"
    if expires_date:
        parsed_date = parse_firestore_date(expires_date)
        if parsed_date:
            expires_formatted = format_date_french(parsed_date)
        else:
            # Debug: log the actual format we received
            print(f"DEBUG: Could not parse expiresAt: {type(expires_date)}, value: {expires_date}")
    
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
    .header {{ background-color: #6B4423; color: white; padding: 20px; text-align: center; }}
    .content {{ background-color: #F5F1E8; padding: 20px; }}
    .info-row {{ margin: 10px 0; }}
    .label {{ font-weight: bold; color: #6B4423; }}
    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
    .gift-box {{ background-color: #fff; border: 2px dashed #6B4423; border-radius: 10px; padding: 30px; margin: 20px 0; text-align: center; }}
    .amount {{ font-size: 48px; font-weight: bold; color: #6B4423; margin: 20px 0; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🎁 Vous avez reçu un bon cadeau !</h1>
    </div>
    <div class="content">
      <p>Bonjour {voucher.get("recipientName", "")},</p>
      <p>Vous avez reçu un bon cadeau Harmonya de la part de <strong>{voucher.get("purchaserName", "quelqu'un qui vous aime")}</strong> !</p>
      <div class="gift-box">
        <div class="amount">{voucher.get("amount", 0)}€</div>
        <p style="font-size: 18px; color: #6B4423; font-weight: bold;">
          Bon cadeau Harmonya
        </p>
      </div>
      {message_html}
      <div class="info-row">
        <span class="label">Valable jusqu'au:</span> {expires_formatted}
      </div>
      <p style="margin-top: 20px;">
        Pour utiliser votre bon cadeau, réservez votre massage sur notre site web ou contactez-nous directement.
      </p>
      <p style="margin-top: 20px;">
        <a href="https://harmonyamassage.fr" style="background-color: #6B4423; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
          Réserver maintenant
        </a>
      </p>
      <p>Cordialement,<br><strong>L'équipe Harmonya</strong></p>
    </div>
    <div class="footer">
      <p><strong>Harmonya</strong></p>
      <p>1 A rue de la poste<br>67400 ILLKIRCH GRAFFENSTADEN</p>
      <p>Téléphone: 06 26 14 25 89</p>
      <p><a href="https://harmonyamassage.fr" style="color: #6B4423; text-decoration: none;">harmonyamassage.fr</a></p>
    </div>
  </div>
</body>
</html>
"""


def get_html_template_voucher_admin(voucher: dict, voucher_id: str) -> str:
    """Génère le template HTML pour l'email admin lors d'un achat de bon cadeau"""
    message_html = ""
    if voucher.get("message"):
        message_html = f"""
      <div class="info-row">
        <span class="label">Message:</span> {voucher.get("message")}
      </div>
        """
    
    expires_date = voucher.get("expiresAt")
    expires_formatted = "Date non spécifiée"
    if expires_date:
        parsed_date = parse_firestore_date(expires_date)
        if parsed_date:
            expires_formatted = format_date_french(parsed_date)
        else:
            # Debug: log the actual format we received
            print(f"DEBUG: Could not parse expiresAt: {type(expires_date)}, value: {expires_date}")
    
    paid_date = voucher.get("paidAt")
    paid_formatted = "Non payé"
    if paid_date:
        if isinstance(paid_date, dict):
            seconds = paid_date.get("_seconds") or paid_date.get("seconds", 0)
            if seconds:
                paid_date = datetime.fromtimestamp(seconds)
                paid_formatted = format_date_french(paid_date)
        elif hasattr(paid_date, 'to_datetime'):
            paid_date = paid_date.to_datetime()
            paid_formatted = format_date_french(paid_date)
    
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
    .header {{ background-color: #6B4423; color: white; padding: 20px; text-align: center; }}
    .content {{ background-color: #F5F1E8; padding: 20px; }}
    .info-row {{ margin: 10px 0; }}
    .label {{ font-weight: bold; color: #6B4423; }}
    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Nouveau Bon Cadeau</h1>
    </div>
    <div class="content">
      <p>Un nouveau bon cadeau a été acheté :</p>
      <div class="info-row">
        <span class="label">Montant:</span> {voucher.get("amount", 0)}€
      </div>
      <div class="info-row">
        <span class="label">Acheteur:</span> {voucher.get("purchaserName", "")} ({voucher.get("purchaserEmail", "")})
      </div>
      <div class="info-row">
        <span class="label">Destinataire:</span> {voucher.get("recipientName", "")} ({voucher.get("recipientEmail", "")})
      </div>
      {message_html}
      <div class="info-row">
        <span class="label">Statut:</span> {voucher.get("status", "pending")}
      </div>
      <div class="info-row">
        <span class="label">Date de paiement:</span> {paid_formatted}
      </div>
      <div class="info-row">
        <span class="label">Valable jusqu'au:</span> {expires_formatted}
      </div>
      {f'<div class="info-row"><span class="label">ID PayPal:</span> {voucher.get("paypalOrderId", "")}</div>' if voucher.get("paypalOrderId") else ''}
      <div class="info-row">
        <span class="label">ID Bon cadeau:</span> {voucher_id}
      </div>
    </div>
    <div class="footer">
      <p>Harmonya - Massage & Bien-être</p>
      <p>1 A rue de la poste 67400 ILLKIRCH GRAFFENSTADEN</p>
      <p><a href="https://harmonyamassage.fr" style="color: #6B4423; text-decoration: none;">harmonyamassage.fr</a></p>
    </div>
  </div>
</body>
</html>
"""


def _send_email_with_retry(email_data: dict, email_type: str, voucher_id: str, max_retries: int = 3) -> bool:
    """
    Helper function pour envoyer un email avec retry en cas de rate limit
    Resend limite à 2 requêtes par seconde
    """
    for attempt in range(max_retries):
        try:
            result = resend.Emails.send(email_data)
            print(f"Email {email_type} envoyé avec succès pour le bon cadeau {voucher_id}: {result}")
            return True
        except Exception as e:
            error_str = str(e)
            # Vérifier si c'est une erreur de rate limit
            if "rate limit" in error_str.lower() or "too many requests" in error_str.lower():
                if attempt < max_retries - 1:
                    # Attendre avec backoff exponentiel: 0.6s, 1.2s, 2.4s
                    wait_time = 0.6 * (2 ** attempt)
                    print(f"Rate limit atteint pour {email_type}, attente de {wait_time}s avant retry (tentative {attempt + 1}/{max_retries})")
                    time.sleep(wait_time)
                    continue
                else:
                    print(f"ERREUR: Rate limit toujours atteint après {max_retries} tentatives pour {email_type}")
                    import traceback
                    traceback.print_exc()
                    return False
            else:
                # Autre erreur, ne pas retry
                print(f"ERREUR lors de l'envoi de l'email {email_type}: {error_str}")
                import traceback
                traceback.print_exc()
                return False
    return False


def _send_voucher_emails_helper(voucher: dict, voucher_id: str) -> None:
    """
    Helper function pour envoyer les emails de bon cadeau
    Respecte la limite de rate de Resend (2 requêtes/seconde)
    """
    print(f"DEBUG _send_voucher_emails_helper: Début envoi emails pour voucher {voucher_id}")
    
    # Vérifier que Resend API Key est configurée
    api_key = get_resend_api_key()
    if not api_key:
        print(f"ERREUR: RESEND_API_KEY non configurée pour le bon cadeau {voucher_id}")
        return
    resend.api_key = api_key
    
    # Envoyer l'email à l'acheteur (seulement si différent du destinataire)
    purchaser_email = voucher.get("purchaserEmail")
    recipient_email = voucher.get("recipientEmail")
    
    print(f"DEBUG _send_voucher_emails_helper: purchaser_email={purchaser_email}, recipient_email={recipient_email}")
    
    if not recipient_email:
        print(f"ERREUR: Aucun email destinataire trouvé pour le bon cadeau {voucher_id}")
        return
    
    # Liste des emails à envoyer (pour respecter le rate limit)
    emails_to_send = []
    
    if purchaser_email and purchaser_email != recipient_email:
        purchaser_html = get_html_template_voucher_purchaser(voucher, voucher_id)
        emails_to_send.append({
            "type": "acheteur",
            "to": purchaser_email,
            "subject": "Confirmation d'achat - Bon cadeau Harmonya",
            "html": purchaser_html,
        })
    elif purchaser_email == recipient_email:
        print(f"Email acheteur ignoré pour le bon cadeau {voucher_id} (même email que le destinataire)")
    
    # Email destinataire (prioritaire)
    recipient_html = get_html_template_voucher_recipient(voucher, voucher_id)
    emails_to_send.append({
        "type": "destinataire",
        "to": recipient_email,
        "subject": "🎁 Vous avez reçu un bon cadeau Harmonya !",
        "html": recipient_html,
    })
    
    # Email admin
    admin_html = get_html_template_voucher_admin(voucher, voucher_id)
    emails_to_send.append({
        "type": "admin",
        "to": ADMIN_EMAIL,
        "subject": f"Nouveau bon cadeau - {voucher.get('amount', 0)}€",
        "html": admin_html,
    })
    
    # Envoyer les emails avec délai entre chaque pour respecter le rate limit (2 req/s)
    # Attendre 0.6 secondes entre chaque email pour être sûr de rester sous la limite
    for i, email_info in enumerate(emails_to_send):
        if i > 0:
            # Attendre avant d'envoyer le prochain email (sauf pour le premier)
            time.sleep(0.6)
        
        print(f"DEBUG _send_voucher_emails_helper: Envoi email {email_info['type']} à {email_info['to']}")
        
        email_data = {
            "from": FROM_EMAIL,
            "to": email_info["to"],
            "subject": email_info["subject"],
            "html": email_info["html"],
        }
        
        _send_email_with_retry(email_data, email_info["type"], voucher_id)


@firestore_fn.on_document_created(
    document="giftVouchers/{voucherId}",
    region="europe-west9",
    secrets=["RESEND_API_KEY"]
)
def send_voucher_emails_on_create(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """
    Fonction déclenchée automatiquement lorsqu'un bon cadeau est créé avec statut "paid"
    Envoie des emails à l'acheteur, au destinataire et à l'admin
    """
    try:
        snapshot = event.data
        if snapshot is None:
            print("Aucune donnée dans l'événement (create)")
            return
        
        voucher = snapshot.to_dict()
        voucher_id = snapshot.id
        
        if voucher is None:
            print(f"Aucune donnée trouvée pour le bon cadeau {voucher_id} (create)")
            return
        
        status = voucher.get("status") or "pending"
        print(f"DEBUG send_voucher_emails_on_create: Voucher {voucher_id} créé avec statut: {status}")
        
        if status == "paid":
            print(f"DEBUG send_voucher_emails_on_create: Voucher {voucher_id} créé avec statut 'paid', envoi des emails...")
            _send_voucher_emails_helper(voucher, voucher_id)
        else:
            print(f"DEBUG send_voucher_emails_on_create: Voucher {voucher_id} créé avec statut '{status}', pas d'envoi d'email")
                
    except Exception as e:
        print(f"Erreur générale dans send_voucher_emails_on_create: {str(e)}")
        import traceback
        traceback.print_exc()


@firestore_fn.on_document_updated(
    document="giftVouchers/{voucherId}",
    region="europe-west9",
    secrets=["RESEND_API_KEY"]
)
def send_voucher_emails(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Fonction déclenchée automatiquement lorsqu'un bon cadeau est mis à jour (paiement confirmé)
    Envoie des emails à l'acheteur, au destinataire et à l'admin
    """
    try:
        snapshot = event.data
        if snapshot is None:
            print("Aucune donnée dans l'événement (update)")
            return
        
        voucher_after = snapshot.after.to_dict()
        voucher_before = snapshot.before.to_dict() if snapshot.before else {}
        voucher_id = snapshot.after.id
        
        if voucher_after is None:
            print(f"Aucune donnée trouvée pour le bon cadeau {voucher_id} (update)")
            return
        
        # Vérifier si le statut a changé de "pending" à "paid"
        status_before = voucher_before.get("status") or "pending"
        status_after = voucher_after.get("status") or "pending"
        
        print(f"DEBUG send_voucher_emails: Voucher {voucher_id} - Status before: {status_before}, Status after: {status_after}")
        
        if status_before != "paid" and status_after == "paid":
            # Le bon cadeau vient d'être payé, envoyer les emails
            print(f"DEBUG send_voucher_emails: Voucher {voucher_id} vient d'être payé, préparation des emails...")
            _send_voucher_emails_helper(voucher_after, voucher_id)
        else:
            print(f"DEBUG send_voucher_emails: Voucher {voucher_id} - Pas de changement de statut vers 'paid' (before={status_before}, after={status_after})")
                
    except Exception as e:
        print(f"Erreur générale dans send_voucher_emails: {str(e)}")
        import traceback
        traceback.print_exc()


def get_html_template_contact_message(contact: dict, contact_id: str, date_formatted: str) -> str:
    """
    Génère le template HTML pour l'email admin lors d'un nouveau message de contact
    """
    name = contact.get("name", "Non spécifié")
    message = contact.get("message", "")
    contact_method = contact.get("contactMethod", "")
    email = contact.get("email", "")
    phone = contact.get("phone", "")
    
    # Traduire la méthode de contact
    contact_method_text = {
        "email": "Par email",
        "phone": "Par téléphone",
        "no_answer": "Je n'ai pas besoin de réponse"
    }.get(contact_method, contact_method)
    
    # Construire les informations de contact
    contact_info_html = ""
    if contact_method == "email" and email:
        contact_info_html = f'<div class="info-row"><span class="label">Email:</span> {email}</div>'
    elif contact_method == "phone" and phone:
        contact_info_html = f'<div class="info-row"><span class="label">Téléphone:</span> {phone}</div>'
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body {{
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
            }}
            .header {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                text-align: center;
                border-radius: 10px 10px 0 0;
            }}
            .content {{
                background: #f9f9f9;
                padding: 30px;
                border-radius: 0 0 10px 10px;
            }}
            .info-row {{
                margin: 15px 0;
                padding: 10px;
                background: white;
                border-left: 4px solid #667eea;
                border-radius: 4px;
            }}
            .label {{
                font-weight: bold;
                color: #667eea;
                display: inline-block;
                min-width: 150px;
            }}
            .message-box {{
                background: white;
                padding: 20px;
                border-radius: 8px;
                margin: 20px 0;
                border-left: 4px solid #764ba2;
            }}
            .footer {{
                text-align: center;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #ddd;
                color: #666;
                font-size: 12px;
            }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Nouveau Message de Contact</h1>
        </div>
        <div class="content">
            <div class="info-row">
                <span class="label">Nom:</span> {name}
            </div>
            <div class="info-row">
                <span class="label">Date:</span> {date_formatted}
            </div>
            <div class="info-row">
                <span class="label">Méthode de contact:</span> {contact_method_text}
            </div>
            {contact_info_html}
            <div class="message-box">
                <h3 style="margin-top: 0; color: #764ba2;">Message:</h3>
                <p style="white-space: pre-wrap;">{message}</p>
            </div>
            <div class="info-row" style="background: #fff3cd; border-left-color: #ffc107;">
                <span class="label">ID du message:</span> {contact_id}
            </div>
        </div>
        <div class="footer">
            <p>Ce message a été envoyé depuis le formulaire de contact du site Harmonya Massage.</p>
        </div>
    </body>
    </html>
    """


@firestore_fn.on_document_created(
    document="contactMessages/{contactId}",
    region="europe-west9",
    secrets=["RESEND_API_KEY"]
)
def send_contact_message_email(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Fonction déclenchée automatiquement lorsqu'un nouveau message de contact est créé
    Envoie un email à l'administrateur avec les détails du message
    """
    try:
        # Récupérer les données du message de contact
        snapshot = event.data
        if snapshot is None:
            print("Aucune donnée dans l'événement")
            return
        
        contact = snapshot.to_dict()
        contact_id = snapshot.id
        
        if contact is None:
            print(f"Aucune donnée trouvée pour le message de contact {contact_id}")
            return
        
        # Formater la date en français
        date_timestamp = contact.get("createdAt")
        if date_timestamp:
            # Convertir Timestamp Firestore en datetime si nécessaire
            if hasattr(date_timestamp, 'to_datetime'):
                date_timestamp = date_timestamp.to_datetime()
            elif isinstance(date_timestamp, dict):
                # Format Firestore Timestamp
                seconds = date_timestamp.get("_seconds") or date_timestamp.get("seconds", 0)
                nanoseconds = date_timestamp.get("_nanoseconds") or date_timestamp.get("nanoseconds", 0)
                date_timestamp = datetime.fromtimestamp(seconds + nanoseconds / 1e9)
            date_formatted = format_date_french(date_timestamp)
        else:
            date_formatted = "Date non spécifiée"
        
        # Vérifier que Resend API Key est configurée
        api_key = get_resend_api_key()
        if not api_key:
            print(f"ERREUR: RESEND_API_KEY non configurée pour le message de contact {contact_id}")
            return
        resend.api_key = api_key
        
        # Envoyer l'email à l'administrateur
        try:
            admin_html = get_html_template_contact_message(contact, contact_id, date_formatted)
            
            # Nom pour le sujet
            name = contact.get("name", "Anonyme")
            contact_method = contact.get("contactMethod", "")
            
            # Construire le sujet
            subject = f"Nouveau message de contact de {name}"
            if contact_method == "email":
                email = contact.get("email", "")
                if email:
                    subject += f" ({email})"
            elif contact_method == "phone":
                phone = contact.get("phone", "")
                if phone:
                    subject += f" ({phone})"
            
            result = resend.Emails.send({
                "from": FROM_EMAIL,
                "to": ADMIN_EMAIL,
                "subject": subject,
                "html": admin_html,
            })
            print(f"Email admin envoyé avec succès pour le message de contact {contact_id}: {result}")
        except Exception as e:
            print(f"Erreur lors de l'envoi de l'email admin: {str(e)}")
            import traceback
            traceback.print_exc()
            
    except Exception as e:
        print(f"Erreur générale dans send_contact_message_email: {str(e)}")
        import traceback
        traceback.print_exc()


@firestore_fn.on_document_updated(
    document="contactMessages/{contactId}",
    region="europe-west9",
    secrets=["RESEND_API_KEY"]
)
def send_contact_answer_email(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Fonction déclenchée lorsqu'un message de contact est mis à jour
    Envoie un email au client avec la réponse si le message a été répondu
    """
    try:
        # Récupérer les données avant et après la mise à jour
        before_snapshot = event.data.before
        after_snapshot = event.data.after
        
        if before_snapshot is None or after_snapshot is None:
            print("Données manquantes dans l'événement de mise à jour")
            return
        
        before_data = before_snapshot.to_dict()
        after_data = after_snapshot.to_dict()
        contact_id = after_snapshot.id
        
        if before_data is None or after_data is None:
            print(f"Aucune donnée trouvée pour le message de contact {contact_id}")
            return
        
        # Vérifier les conditions:
        # 1. contactMethod == 'email'
        contact_method = after_data.get("contactMethod", "")
        if contact_method != "email":
            print(f"Message {contact_id} n'est pas un email, pas d'envoi de réponse")
            return
        
        # 2. answered == true dans le nouveau document
        answered = after_data.get("answered", False)
        if not answered:
            print(f"Message {contact_id} n'est pas marqué comme répondu")
            return
        
        # 3. answered == false dans l'ancien document (vient d'être répondu)
        old_answered = before_data.get("answered", False)
        if old_answered:
            print(f"Message {contact_id} était déjà répondu, pas d'envoi de réponse")
            return
        
        # 4. Le document a la clé "answer" et elle n'est pas vide
        answer = after_data.get("answer", "")
        if not answer or answer.strip() == "":
            print(f"Message {contact_id} n'a pas de réponse valide")
            return
        
        # Récupérer l'email du client
        email = after_data.get("email", "")
        if not email or email.strip() == "":
            print(f"Message {contact_id} n'a pas d'email valide")
            return
        
        # Vérifier que Resend API Key est configurée
        api_key = get_resend_api_key()
        if not api_key:
            print(f"ERREUR: RESEND_API_KEY non configurée pour la réponse au message {contact_id}")
            return
        resend.api_key = api_key
        
        # Récupérer le nom du client pour personnaliser l'email
        name = after_data.get("name", "Client")
        
        # Récupérer le message original
        original_message = after_data.get("message", "")
        
        # Envoyer l'email au client avec la réponse
        try:
            # Créer le template HTML pour l'email de réponse
            html_body = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body {{
                        font-family: Arial, sans-serif;
                        line-height: 1.6;
                        color: #333;
                        max-width: 600px;
                        margin: 0 auto;
                        padding: 20px;
                    }}
                    .header {{
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        padding: 30px;
                        text-align: center;
                        border-radius: 10px 10px 0 0;
                    }}
                    .content {{
                        background: #f9f9f9;
                        padding: 30px;
                        border-radius: 0 0 10px 10px;
                    }}
                    .message-box {{
                        background: white;
                        padding: 20px;
                        border-radius: 8px;
                        margin: 20px 0;
                        border-left: 4px solid #667eea;
                    }}
                    .original-message-box {{
                        background: #f0f0f0;
                        padding: 20px;
                        border-radius: 8px;
                        margin: 20px 0;
                        border-left: 4px solid #999;
                    }}
                    .footer {{
                        text-align: center;
                        margin-top: 30px;
                        padding-top: 20px;
                        border-top: 1px solid #ddd;
                        color: #666;
                        font-size: 12px;
                    }}
                </style>
            </head>
            <body>
                <div class="header">
                    <h1>Réponse à votre message</h1>
                </div>
                <div class="content">
                    <p>Bonjour {name},</p>
                    <p>Nous avons bien reçu votre message et nous vous répondons ci-dessous :</p>
                    <div class="original-message-box">
                        <p style="font-weight: bold; margin-top: 0; color: #666;">Votre message :</p>
                        <p style="white-space: pre-wrap; margin: 0;">{original_message}</p>
                    </div>
                    <div class="message-box">
                        <p style="font-weight: bold; margin-top: 0; color: #667eea;">Notre réponse :</p>
                        <p style="white-space: pre-wrap; margin: 0;">{answer}</p>
                    </div>
                    <p>N'hésitez pas à nous contacter si vous avez d'autres questions.</p>
                    <p>Cordialement,<br>L'équipe Harmonya</p>
                    <p style="text-align: center; margin-top: 20px;">
                        <a href="https://harmonyamassage.fr" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold;">Visitez notre site web</a>
                    </p>
                </div>
                <div class="footer">
                    <p>Harmonya Massage & Bien-être</p>
                    <p>1 A rue de la poste, 67400 ILLKIRCH GRAFFENSTADEN</p>
                    <p>Téléphone: 06 26 14 25 89</p>
                    <p><a href="https://harmonyamassage.fr" style="color: #667eea; text-decoration: none;">https://harmonyamassage.fr</a></p>
                </div>
            </body>
            </html>
            """
            
            result = resend.Emails.send({
                "from": FROM_EMAIL,
                "to": email.strip(),
                "subject": f"Réponse à votre message - Harmonya",
                "html": html_body,
            })
            print(f"Email de réponse envoyé avec succès pour le message {contact_id} à {email}: {result}")
        except Exception as e:
            print(f"Erreur lors de l'envoi de l'email de réponse: {str(e)}")
            import traceback
            traceback.print_exc()
            
    except Exception as e:
        print(f"Erreur générale dans send_contact_answer_email: {str(e)}")
        import traceback
        traceback.print_exc()


def update_customer_service_names(
    service_id: str,
    new_name: str,
    service_type_field: str,
    service_names_field: str,
    service_type_label: str
) -> None:
    """
    Fonction générique pour mettre à jour les noms de service dans les documents clients
    
    Args:
        service_id: L'ID du service (massage ou traitement)
        new_name: Le nouveau nom du service
        service_type_field: Le nom du champ contenant les IDs (ex: "massageTypes" ou "treatmentTypes")
        service_names_field: Le nom du champ contenant les noms (ex: "massageTypesNames" ou "treatmentTypesNames")
        service_type_label: Le label pour les logs (ex: "massage" ou "traitement")
    """
    try:
        print(f"Le nom du {service_type_label} {service_id} a changé vers '{new_name}'")
        
        # Récupérer tous les clients qui ont ce service dans leur liste
        db = firestore.client()
        customers_ref = db.collection("customers")
        
        # Query pour trouver les clients avec ce service ID dans le tableau approprié
        customers_query = customers_ref.where(service_type_field, "array_contains", service_id).stream()
        
        # Collecter toutes les mises à jour
        updates = []
        for customer_doc in customers_query:
            try:
                customer_data = customer_doc.to_dict()
                service_types = customer_data.get(service_type_field, [])
                service_types_names = customer_data.get(service_names_field, [])
                
                # Trouver l'index du service ID dans le tableau
                if service_id in service_types:
                    index = service_types.index(service_id)
                    # Mettre à jour le nom correspondant
                    if index < len(service_types_names):
                        service_types_names[index] = new_name
                    else:
                        # Si le tableau des noms est plus court, l'étendre
                        while len(service_types_names) < index:
                            service_types_names.append("")
                        service_types_names.append(new_name)
                    
                    # Ajouter à la liste des mises à jour
                    updates.append((customer_doc.reference, service_types_names))
            except Exception as e:
                print(f"Erreur lors du traitement du client {customer_doc.id}: {str(e)}")
                import traceback
                traceback.print_exc()
        
        # Effectuer les mises à jour par batch (max 500 par batch)
        batch_size = 500
        updated_count = 0
        for i in range(0, len(updates), batch_size):
            batch = db.batch()
            batch_updates = updates[i:i + batch_size]
            
            for customer_ref, service_types_names in batch_updates:
                batch.update(customer_ref, {
                    service_names_field: service_types_names
                })
            
            # Commiter le batch
            batch.commit()
            updated_count += len(batch_updates)
            print(f"Batch {i // batch_size + 1}: Mis à jour {len(batch_updates)} client(s)")
        
        print(f"Mis à jour {updated_count} client(s) au total pour le {service_type_label} {service_id}")
        
    except Exception as e:
        print(f"Erreur dans update_customer_service_names: {str(e)}")
        import traceback
        traceback.print_exc()


@firestore_fn.on_document_updated(
    document="massages/{massageId}",
    region="europe-west9"
)
def update_customer_massage_names(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Fonction déclenchée lorsqu'un massage est mis à jour
    Met à jour les noms de massage dans les documents clients si le nom a changé
    """
    try:
        before_snapshot = event.data.before
        after_snapshot = event.data.after
        
        if not before_snapshot or not after_snapshot:
            return
        
        before_data = before_snapshot.to_dict()
        after_data = after_snapshot.to_dict()
        massage_id = after_snapshot.id
        
        # Vérifier si le nom a changé
        old_name = before_data.get("name", "")
        new_name = after_data.get("name", "")
        
        if old_name == new_name or not new_name:
            # Le nom n'a pas changé ou est vide, pas besoin de mettre à jour
            return
        
        # Appeler la fonction générique
        update_customer_service_names(
            service_id=massage_id,
            new_name=new_name,
            service_type_field="massageTypes",
            service_names_field="massageTypesNames",
            service_type_label="massage"
        )
        
    except Exception as e:
        print(f"Erreur dans update_customer_massage_names: {str(e)}")
        import traceback
        traceback.print_exc()


@firestore_fn.on_document_updated(
    document="treatments/{treatmentId}",
    region="europe-west9"
)
def update_customer_treatment_names(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Fonction déclenchée lorsqu'un traitement est mis à jour
    Met à jour les noms de traitement dans les documents clients si le nom a changé
    """
    try:
        before_snapshot = event.data.before
        after_snapshot = event.data.after
        
        if not before_snapshot or not after_snapshot:
            return
        
        before_data = before_snapshot.to_dict()
        after_data = after_snapshot.to_dict()
        treatment_id = after_snapshot.id
        
        # Vérifier si le nom a changé
        old_name = before_data.get("name", "")
        new_name = after_data.get("name", "")
        
        if old_name == new_name or not new_name:
            # Le nom n'a pas changé ou est vide, pas besoin de mettre à jour
            return
        
        # Appeler la fonction générique
        update_customer_service_names(
            service_id=treatment_id,
            new_name=new_name,
            service_type_field="treatmentTypes",
            service_names_field="treatmentTypesNames",
            service_type_label="traitement"
        )
        
    except Exception as e:
        print(f"Erreur dans update_customer_treatment_names: {str(e)}")
        import traceback
        traceback.print_exc()


@https_fn.on_request(region="europe-west9")
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
        # PayPal uses header-based verification (especially in Sandbox mode where signing secret may not be visible)
        # Each webhook request includes these headers:
        # - PAYPAL-TRANSMISSION-ID: Unique transmission ID
        # - PAYPAL-TRANSMISSION-SIG: Cryptographic signature
        # - PAYPAL-TRANSMISSION-TIME: Timestamp
        # - PAYPAL-CERT-URL: URL to PayPal's certificate
        # - PAYPAL-AUTH-ALGO: Algorithm used (usually SHA256withRSA)
        # 
        # To verify, use PayPal's webhook verification API:
        # POST https://api-m.sandbox.paypal.com/v1/notifications/verify-webhook-signature
        # (or https://api-m.paypal.com for production)
        # 
        # Example verification (implement before production):
        # webhook_id = os.environ.get("PAYPAL_WEBHOOK_ID", "")  # Get from webhook details
        # transmission_id = req.headers.get("PAYPAL-TRANSMISSION-ID", "")
        # transmission_sig = req.headers.get("PAYPAL-TRANSMISSION-SIG", "")
        # transmission_time = req.headers.get("PAYPAL-TRANSMISSION-TIME", "")
        # cert_url = req.headers.get("PAYPAL-CERT-URL", "")
        # auth_algo = req.headers.get("PAYPAL-AUTH-ALGO", "")
        # 
        # Verify using PayPal API - see documentation:
        # https://developer.paypal.com/docs/api-basics/notifications/webhooks/notification-messages/
        # 
        # For now, skipping verification for testing (NOT RECOMMENDED FOR PRODUCTION)
        
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
                collection_name = "giftVouchers"  # Explicitly set collection name
                print(f"DEBUG: Attempting to update voucher {custom_id} in collection '{collection_name}'")
                voucher_ref = firestore.client().collection(collection_name).document(custom_id)
                
                # Check if document exists first
                doc = voucher_ref.get()
                if not doc.exists:
                    print(f"ERROR: Voucher document {custom_id} does not exist in collection '{collection_name}'")
                    return https_fn.Response(
                        json.dumps({"error": f"Voucher {custom_id} not found in collection '{collection_name}'"}),
                        status=404,
                        mimetype="application/json"
                    )
                
                try:
                    voucher_ref.update({
                        "status": "paid",
                        "paidAt": firestore.SERVER_TIMESTAMP,
                        "paypalOrderId": order_id,
                    })
                    print(f"Updated voucher {custom_id} to paid status in collection '{collection_name}'")
                except Exception as update_error:
                    print(f"ERROR updating voucher {custom_id}: {str(update_error)}")
                    raise update_error
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
                collection_name = "giftVouchers"  # Explicitly set collection name
                print(f"DEBUG: Attempting to update voucher {custom_id} in collection '{collection_name}'")
                voucher_ref = firestore.client().collection(collection_name).document(custom_id)
                
                # Check if document exists first
                doc = voucher_ref.get()
                if not doc.exists:
                    print(f"ERROR: Voucher document {custom_id} does not exist in collection '{collection_name}'")
                    return https_fn.Response(
                        json.dumps({"error": f"Voucher {custom_id} not found in collection '{collection_name}'"}),
                        status=404,
                        mimetype="application/json"
                    )
                
                try:
                    voucher_ref.update({
                        "status": "refunded",
                    })
                    print(f"Updated voucher {custom_id} to refunded status in collection '{collection_name}'")
                except Exception as update_error:
                    print(f"ERROR updating voucher {custom_id}: {str(update_error)}")
                    raise update_error
            
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
