/**
 * Backend RailSkills - Serveur de tokens SharePoint
 * 
 * Ce serveur gère le Client Secret Azure AD de manière sécurisée
 * et fournit des tokens d'accès SharePoint aux clients iOS
 * 
 * Architecture:
 *   iPad → Backend (ce serveur) → Azure AD → SharePoint
 * 
 * Avantages:
 *   ✅ Client Secret jamais exposé
 *   ✅ Rotation des secrets simplifiée
 *   ✅ Audit centralisé
 *   ✅ Conforme guidelines Apple
 */

const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

// Configuration
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(cors()); // À restreindre en production

// Configuration Azure AD (depuis variables d'environnement)
const AZURE_CONFIG = {
    tenantId: process.env.AZURE_TENANT_ID || '4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9',
    clientId: process.env.AZURE_CLIENT_ID || 'bd394412-97bf-4513-a59f-e023b010dff7',
    clientSecret: process.env.AZURE_CLIENT_SECRET, // ⚠️ Ne JAMAIS commiter
    scope: 'https://graph.microsoft.com/.default'
};

// Vérifier la configuration au démarrage
if (!AZURE_CONFIG.clientSecret) {
    console.error('❌ ERREUR: AZURE_CLIENT_SECRET non configuré');
    console.error('Créez un fichier .env avec:');
    console.error('AZURE_CLIENT_SECRET=votre_client_secret_ici');
    process.exit(1);
}

// Cache de tokens (simple - en production, utiliser Redis)
let tokenCache = {
    token: null,
    expiresAt: null
};

// ============================================================================
// ROUTES
// ============================================================================

/**
 * Health check
 * GET /api/health
 */
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'RailSkills Backend',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

/**
 * Obtenir un token SharePoint
 * POST /api/sharepoint/token
 * 
 * Body (optionnel):
 * {
 *   "appVersion": "2.0",
 *   "platform": "iOS"
 * }
 */
app.post('/api/sharepoint/token', async (req, res) => {
    try {
        // Log de la requête (optionnel)
        const { appVersion, platform } = req.body;
        console.log(`📱 Demande de token depuis ${platform || 'unknown'} v${appVersion || 'unknown'}`);
        
        // Vérifier le cache
        if (tokenCache.token && tokenCache.expiresAt && Date.now() < tokenCache.expiresAt) {
            console.log('✅ Token retourné depuis le cache');
            const secondsRemaining = Math.floor((tokenCache.expiresAt - Date.now()) / 1000);
            return res.json({
                accessToken: tokenCache.token,
                expiresIn: secondsRemaining,
                tokenType: 'Bearer',
                cached: true
            });
        }
        
        // Demander un nouveau token à Azure AD
        console.log('🔄 Demande d\'un nouveau token à Azure AD...');
        const token = await getAzureToken();
        
        res.json({
            accessToken: token.accessToken,
            expiresIn: token.expiresIn,
            tokenType: token.tokenType,
            cached: false
        });
        
    } catch (error) {
        console.error('❌ Erreur lors de l\'obtention du token:', error.message);
        res.status(500).json({
            error: 'TOKEN_ERROR',
            message: 'Impossible d\'obtenir un token SharePoint',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

/**
 * Invalider le cache de token (utile pour forcer un refresh)
 * POST /api/sharepoint/token/invalidate
 */
app.post('/api/sharepoint/token/invalidate', (req, res) => {
    tokenCache = {
        token: null,
        expiresAt: null
    };
    console.log('🗑️  Cache de token invalidé');
    res.json({ message: 'Token cache invalidé' });
});

/**
 * Statistiques (debug uniquement)
 * GET /api/stats
 */
app.get('/api/stats', (req, res) => {
    const hasToken = !!tokenCache.token;
    const expiresIn = tokenCache.expiresAt ? Math.floor((tokenCache.expiresAt - Date.now()) / 1000) : 0;
    
    res.json({
        tokenCached: hasToken,
        tokenExpiresIn: expiresIn > 0 ? expiresIn : null,
        configValid: !!AZURE_CONFIG.clientSecret,
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

// ============================================================================
// FONCTIONS UTILITAIRES
// ============================================================================

/**
 * Obtient un token d'accès depuis Azure AD
 * @returns {Promise<{accessToken: string, expiresIn: number, tokenType: string}>}
 */
async function getAzureToken() {
    const tokenUrl = `https://login.microsoftonline.com/${AZURE_CONFIG.tenantId}/oauth2/v2.0/token`;
    
    const params = new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: AZURE_CONFIG.clientId,
        client_secret: AZURE_CONFIG.clientSecret,
        scope: AZURE_CONFIG.scope
    });
    
    try {
        const response = await axios.post(tokenUrl, params.toString(), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });
        
        const { access_token, expires_in, token_type } = response.data;
        
        // Mettre en cache (avec marge de sécurité de 5 minutes)
        tokenCache = {
            token: access_token,
            expiresAt: Date.now() + ((expires_in - 300) * 1000)
        };
        
        console.log(`✅ Nouveau token obtenu (expire dans ${expires_in}s)`);
        
        return {
            accessToken: access_token,
            expiresIn: expires_in,
            tokenType: token_type
        };
        
    } catch (error) {
        console.error('❌ Erreur Azure AD:', error.response?.data || error.message);
        throw new Error('Échec de l\'authentification Azure AD');
    }
}

// ============================================================================
// DÉMARRAGE DU SERVEUR
// ============================================================================

app.listen(PORT, () => {
    console.log('');
    console.log('═══════════════════════════════════════════════════════');
    console.log('🚀 Backend RailSkills démarré');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`📡 Port: ${PORT}`);
    console.log(`🔐 Azure Tenant: ${AZURE_CONFIG.tenantId}`);
    console.log(`🔐 Client ID: ${AZURE_CONFIG.clientId}`);
    console.log(`✅ Client Secret: Configuré`);
    console.log('');
    console.log('Endpoints disponibles:');
    console.log(`  GET  http://localhost:${PORT}/api/health`);
    console.log(`  POST http://localhost:${PORT}/api/sharepoint/token`);
    console.log(`  GET  http://localhost:${PORT}/api/stats`);
    console.log('═══════════════════════════════════════════════════════');
    console.log('');
});

// Gestion des erreurs non capturées
process.on('unhandledRejection', (error) => {
    console.error('❌ Erreur non gérée:', error);
});


