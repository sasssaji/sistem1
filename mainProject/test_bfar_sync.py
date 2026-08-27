#!/usr/bin/env python
"""Test script for BFAR PDF parsing implementation"""

import os
import sys
import django
import logging

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mainProject.settings')
django.setup()

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

from prediction.services.bfar import sync_latest_advisory
from prediction.models import ShellfishAdvisory

def print_section(title):
    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)

def print_advisory(advisory):
    if not advisory:
        print("No advisory found")
        return
    
    print(f"Bulletin Number: {advisory.bulletin_number}")
    print(f"Title: {advisory.title}")
    print(f"Date: {advisory.advisory_date}")
    print(f"Status: {advisory.status}")
    print(f"Affected Areas:\n{advisory.affected_areas}")
    print(f"\nImportant Information:\n{advisory.important_information[:300]}...")
    print(f"\nPDF Info:")
    print(f"  URL: {advisory.pdf_url}")
    print(f"  Filename: {advisory.pdf_filename}")
    print(f"  Size: {advisory.pdf_size}")
    print(f"  SHA256: {advisory.pdf_sha256[:16]}...")
    print(f"  Last Checked: {advisory.last_checked_at}")

try:
    print_section("BEFORE SYNC")
    advisory_before = ShellfishAdvisory.objects.first()
    print_advisory(advisory_before)

    print_section("SYNCING LATEST ADVISORY (FORCED)")
    sync_result = sync_latest_advisory(force=True)
    print(f"Sync result: {sync_result}")

    print_section("AFTER SYNC")
    advisory_after = ShellfishAdvisory.objects.first()
    print_advisory(advisory_after)

    print_section("TEST SUMMARY")
    if sync_result.get('attempted'):
        print("✓ Sync was attempted")
        if sync_result.get('changed'):
            print("✓ New advisory was created/updated")
        else:
            print(f"✓ No new advisory (same or error: {sync_result.get('error', 'none')})")
    else:
        print("✓ Sync was skipped (within interval)")

    if advisory_after:
        print("✓ Advisory is available")
        if advisory_after.bulletin_number and advisory_after.bulletin_number != advisory_after.pdf_url:
            print(f"✓ Bulletin number extracted correctly: {advisory_after.bulletin_number}")
        else:
            print(f"✗ Bulletin number may not be extracted correctly: {advisory_after.bulletin_number}")
        
        if advisory_after.status:
            print(f"✓ Status extracted: {advisory_after.status}")
        else:
            print("✗ Status not extracted")
            
        if advisory_after.affected_areas:
            print(f"✓ Affected areas extracted: {len(advisory_after.affected_areas.split(chr(10)))} areas")
        else:
            print("✗ Affected areas not extracted")
            
        if advisory_after.important_information:
            print("✓ Important information extracted")
        else:
            print("✗ Important information not extracted")
    else:
        print("✗ No advisory available after sync")

    print_section("END OF TEST")

except Exception as exc:
    logger.error(f"Test failed with exception: {exc}", exc_info=True)
    sys.exit(1)
