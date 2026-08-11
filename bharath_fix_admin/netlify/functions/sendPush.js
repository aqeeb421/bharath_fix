const https = require('https');

exports.handler = async (event, context) => {
  // CORS Preflight Handling
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
      },
      body: ''
    };
  }

  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  try {
    const { targetToken, title, body, data, serverKey } = JSON.parse(event.body || '{}');

    if (!targetToken) {
      return {
        statusCode: 400,
        headers: { 'Access-Control-Allow-Origin': '*' },
        body: JSON.stringify({ error: 'Missing targetToken' })
      };
    }

    const key = serverKey || 'AAAANmaSjAs:APA91bHAYJYlPnDrR4IemlSKF_IbVud0FCw2jduQu1F3IqdGG8qXcEqfkasdYZBsgLN67QMGCyGKjZSb2xgbyarHVkZAAd0R0lJxuIVhlygXWxUxI1vBVPMfBcFKKxMSjFljq7eRmEfl';

    const payload = JSON.stringify({
      to: targetToken,
      priority: 'high',
      notification: {
        title: title || 'BharatFix Alert',
        body: body || '',
        sound: 'default',
        channel_id: 'high_importance_channel',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'

      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        title: title || 'BharatFix Alert',
        body: body || '',
        ...(data || {})
      }
    });

    const options = {
      hostname: 'fcm.googleapis.com',
      path: '/fcm/send',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${key}`,
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const res = await new Promise((resolve, reject) => {
      const req = https.request(options, (response) => {
        let responseBody = '';
        response.on('data', (chunk) => responseBody += chunk);
        response.on('end', () => resolve({ statusCode: response.statusCode, body: responseBody }));
      });
      req.on('error', reject);
      req.write(payload);
      req.end();
    });

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ success: true, fcmResult: res })
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: { 'Access-Control-Allow-Origin': '*' },
      body: JSON.stringify({ error: err.message })
    };
  }
};
