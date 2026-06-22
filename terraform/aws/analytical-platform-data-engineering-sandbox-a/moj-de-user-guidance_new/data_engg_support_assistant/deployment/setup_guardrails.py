import sys
import boto3
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import REGION

class GuardrailManager:
    """Manage Bedrock Guardrail lifecycle"""
    
    def __init__(self):
        self.client = boto3.client('bedrock', region_name=REGION)
        self.name = "smart-rag-content-filter"
    
    def get_guardrail_config(self):
        """Centralized guardrail configuration"""
        return {
            'name': self.name,
            'description': "Content filtering for Smart RAG chatbot",
            
            'contentPolicyConfig': {
                'filtersConfig': [
                    {'type': 'HATE', 'inputStrength': 'MEDIUM', 'outputStrength': 'MEDIUM'},
                    {'type': 'VIOLENCE', 'inputStrength': 'MEDIUM', 'outputStrength': 'MEDIUM'},
                    {'type': 'SEXUAL', 'inputStrength': 'MEDIUM', 'outputStrength': 'MEDIUM'},
                    {'type': 'MISCONDUCT', 'inputStrength': 'MEDIUM', 'outputStrength': 'MEDIUM'}
                ]
            },
            
            'sensitiveInformationPolicyConfig': {
                'piiEntitiesConfig': [
                    {'type': 'EMAIL', 'action': 'BLOCK'},
                    {'type': 'PHONE', 'action': 'BLOCK'},
                    {'type': 'US_SOCIAL_SECURITY_NUMBER', 'action': 'BLOCK'},
                    {'type': 'CREDIT_DEBIT_CARD_NUMBER', 'action': 'BLOCK'},
                    {'type': 'UK_NATIONAL_INSURANCE_NUMBER', 'action': 'BLOCK'}
                ]
            },
            
            # topic policy
            'topicPolicyConfig': {
                'topicsConfig': [
                    {
                        'name': 'Off-Topic',
                        'definition': 'Questions not related to data engineering, analytics, databases, SQL, Python, R, data tools, or technical documentation',
                        'examples': [
                            'What is the weather today?',
                            'Tell me a joke',
                            'Who won the game?'
                        ],
                        'type': 'DENY'
                    }
                ]
            },
            
            'blockedInputMessaging': "I can only answer questions about data engineering and the analytics platform.",
            'blockedOutputsMessaging': "I cannot provide that response."
        }
    
    def find_existing(self):
        """Find existing guardrail by name"""
        response = self.client.list_guardrails()
        for gr in response.get('guardrails', []):
            if gr['name'] == self.name:
                return gr['id'], gr['version']
        return None, None
    
    def create(self):
        """Create new guardrail"""
        print("   → Creating new guardrail...")
        config = self.get_guardrail_config()
        
        response = self.client.create_guardrail(**config)
        guardrail_id = response['guardrailId']
        
        # Publish version
        version_response = self.client.create_guardrail_version(
            guardrailIdentifier=guardrail_id,
            description="Initial production version"
        )
        version = version_response['version']
        
        print(f"   ✓ Created: {guardrail_id}")
        print(f"   ✓ Version: {version}")
        return guardrail_id, version
    
    def update(self, guardrail_id):
        """Update existing guardrail"""
        print(f"   → Updating guardrail: {guardrail_id}")
        config = self.get_guardrail_config()
        
        # Remove 'name' from update (not allowed)
        config.pop('name', None)
        
        response = self.client.update_guardrail(
            guardrailIdentifier=guardrail_id,
            **config
        )
        
        # Create new version
        version_response = self.client.create_guardrail_version(
            guardrailIdentifier=guardrail_id,
            description=f"Updated configuration"
        )
        version = version_response['version']
        
        print(f"   ✓ Updated")
        print(f"   ✓ New version: {version}")
        return guardrail_id, version
    
    def delete(self, guardrail_id):
        """Delete guardrail"""
        print(f"   → Deleting guardrail: {guardrail_id}")
        self.client.delete_guardrail(guardrailIdentifier=guardrail_id)
        print("   ✓ Deleted")
    
    def deploy(self, force_recreate=False):
        """Main deployment logic"""
        print("="*70)
        print("  BEDROCK GUARDRAILS SETUP")
        print("="*70)
        
        existing_id, existing_version = self.find_existing()
        
        if existing_id and force_recreate:
            print(f"\n   Found existing: {existing_id}")
            self.delete(existing_id)
            return self.create()
        
        elif existing_id:
            print(f"\n   Found existing: {existing_id} (v{existing_version})")
            print("   Choose action:")
            print("   1. Update configuration")
            print("   2. Keep existing")
            print("   3. Delete and recreate")
            
            choice = input("\n   Enter choice (1/2/3): ").strip()
            
            if choice == '1':
                return self.update(existing_id)
            elif choice == '3':
                self.delete(existing_id)
                return self.create()
            else:
                print(f"\n   ✓ Using existing guardrail")
                return existing_id, existing_version
        
        else:
            print("\n   No existing guardrail found")
            return self.create()


def main():
    try:
        manager = GuardrailManager()
        guardrail_id, version = manager.deploy()
        
        if guardrail_id:
            print("\n" + "="*70)
            print("✅ GUARDRAIL READY")
            print("="*70)
            print(f"\n   Add to .env:")
            print(f"   GUARDRAIL_ID={guardrail_id}")
            print(f"   GUARDRAIL_VERSION={version}")
            print("\n   Then redeploy Lambda:")
            print("   python deployment/deploy_lambda.py")
        
    except Exception as e:
        print(f"\n Failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)