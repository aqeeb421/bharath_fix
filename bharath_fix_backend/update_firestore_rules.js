const fs = require('fs');
const path = require('path');
const sa = require('./serviceAccountKey.json');
const { GoogleAuth } = require('google-auth-library');

async function deployFirestoreRules() {
  const rulesPath = path.resolve(__dirname, 'firestore.rules');
  const rulesContent = fs.readFileSync(rulesPath, 'utf8');

  const auth = new GoogleAuth({
    credentials: sa,
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });

  const client = await auth.getClient();
  const projectId = sa.project_id;

  console.log(`🚀 Creating new ruleset for project: ${projectId}...`);
  const createRes = await client.request({
    url: `https://firebaserules.googleapis.com/v1/projects/${projectId}/rulesets`,
    method: 'POST',
    data: {
      source: {
        files: [
          {
            name: 'firestore.rules',
            content: rulesContent
          }
        ]
      }
    }
  });

  const newRulesetName = createRes.data.name;
  console.log(`✅ Created ruleset: ${newRulesetName}`);

  console.log(`🚀 Releasing ruleset to cloud.firestore...`);
  const releaseRes = await client.request({
    url: `https://firebaserules.googleapis.com/v1/projects/${projectId}/releases/cloud.firestore`,
    method: 'PATCH',
    data: {
      release: {
        name: `projects/${projectId}/releases/cloud.firestore`,
        rulesetName: newRulesetName
      }
    }
  });

  console.log(`🎉 Successfully deployed and released Firestore rules!`);
  console.log(`Current release:`, releaseRes.data);
}

deployFirestoreRules().catch(err => {
  console.error('❌ Failed to deploy rules:', err.message, err.response?.data || '');
  process.exit(1);
});
