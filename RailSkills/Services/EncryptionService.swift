//
//  EncryptionService.swift
//  RailSkills
//
//  Service de chiffrement/déchiffrement des fichiers d'export/import
//  Utilise un secret organisationnel pour dériver la clé de chiffrement
//  Tous les appareils avec le même secret peuvent déchiffrer automatiquement
//

import Foundation
import CryptoKit
import Security

/// Service de chiffrement utilisant AES-GCM via CryptoKit avec secret organisationnel
enum EncryptionService {
    // MARK: - Constantes
    
    /// Service Keychain pour stocker le secret organisationnel de manière sécurisée
    private static let keychainService = "com.railskills.encryption"
    private static let keychainAccount = "organizationSecret"
    
    /// Clé UserDefaults pour la migration (ancien système)
    private static let organizationSecretKey = "railSkills_organizationSecret"
    
    /// Secret par défaut (pour compatibilité avec les anciens fichiers)
    private static let defaultSecret = "RailSkills.Default.2024"
    
    // MARK: - Gestion du secret organisationnel
    
    /// Récupère le secret organisationnel depuis la Keychain (ou UserDefaults pour migration)
    /// Si aucun secret n'existe, utilise le secret par défaut
    /// - Returns: Le secret organisationnel
    static func getOrganizationSecret() -> String {
        // 1. Essayer de récupérer depuis la Keychain (nouveau système sécurisé)
        if let secret = getSecretFromKeychain() {
            return secret
        }
        
        // 2. Migration depuis UserDefaults (ancien système)
        if let oldSecret = UserDefaults.standard.string(forKey: organizationSecretKey), !oldSecret.isEmpty {
            // Migrer vers Keychain
            if saveSecretToKeychain(oldSecret) {
                UserDefaults.standard.removeObject(forKey: organizationSecretKey)
                Logger.info("Secret organisationnel migré vers Keychain", category: "EncryptionService")
            }
            return oldSecret
        }
        
        // 3. Utiliser le secret par défaut
        return defaultSecret
    }
    
    /// Définit le secret organisationnel dans la Keychain
    /// - Parameter secret: Le nouveau secret à utiliser
    static func setOrganizationSecret(_ secret: String) {
        let trimmedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSecret.isEmpty else {
            Logger.warning("Tentative de définir un secret vide, utilisation du secret par défaut", category: "EncryptionService")
            deleteSecretFromKeychain()
            UserDefaults.standard.removeObject(forKey: organizationSecretKey)
            return
        }
        
        if saveSecretToKeychain(trimmedSecret) {
            // Supprimer l'ancien secret de UserDefaults si présent
            UserDefaults.standard.removeObject(forKey: organizationSecretKey)
            Logger.success("Secret organisationnel mis à jour dans Keychain", category: "EncryptionService")
        } else {
            Logger.error("Échec de la sauvegarde du secret dans Keychain", category: "EncryptionService")
        }
    }
    
    /// Réinitialise le secret à la valeur par défaut
    static func resetToDefaultSecret() {
        deleteSecretFromKeychain()
        UserDefaults.standard.removeObject(forKey: organizationSecretKey)
        Logger.info("Secret réinitialisé à la valeur par défaut", category: "EncryptionService")
    }
    
    // MARK: - Keychain Helpers
    
    /// Récupère le secret depuis la Keychain
    private static func getSecretFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let secret = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return secret
    }
    
    /// Sauvegarde le secret dans la Keychain
    private static func saveSecretToKeychain(_ secret: String) -> Bool {
        // Supprimer l'ancien secret s'il existe
        deleteSecretFromKeychain()
        
        guard let data = secret.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Supprime le secret de la Keychain
    private static func deleteSecretFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Dérive une clé de chiffrement depuis le secret organisationnel
    /// - Parameter secret: Le secret à utiliser (optionnel, utilise le secret stocké si nil)
    /// - Returns: La clé de chiffrement dérivée
    private static func deriveKey(from secret: String? = nil) -> SymmetricKey {
        let secretToUse = secret ?? getOrganizationSecret()
        
        // Utiliser SHA256 pour dériver une clé de 256 bits depuis le secret
        // Ajouter un "salt" basé sur l'identifiant de l'app pour plus de sécurité
        let salt = "ctt.RailSkills.encryption.salt"
        let combinedSecret = "\(secretToUse).\(salt)"
        let secretData = combinedSecret.data(using: .utf8)!
        
        // Dériver la clé avec SHA256
        let hashedKey = SHA256.hash(data: secretData)
        return SymmetricKey(data: hashedKey)
    }
    
    /// Récupère la clé de chiffrement dérivée depuis le secret organisationnel
    /// - Returns: La clé de chiffrement
    static func getEncryptionKey() -> SymmetricKey {
        return deriveKey()
    }
    
    /// Vérifie la dérivation de la clé et log les informations de diagnostic
    static func verifyKeyDerivation() {
        let secret = getOrganizationSecret()
        let salt = "ctt.RailSkills.encryption.salt"
        let keyMaterial = "\(secret).\(salt)"
        let keyData = Data(keyMaterial.utf8)
        let hash = SHA256.hash(data: keyData)
        let derivedKey = SymmetricKey(data: hash)
        
        let keyBytes = derivedKey.withUnsafeBytes { Data($0) }
        let keyHex = keyBytes.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " ")
        
        Logger.info("🔍 [EncryptionService] Vérification de la dérivation de clé", category: "EncryptionService")
        Logger.info("   Secret organisationnel: \(secret.count > 8 ? "\(secret.prefix(4))...\(secret.suffix(4))" : "***") (longueur: \(secret.count) caractères)", category: "EncryptionService")
        Logger.info("   Salt: \(salt)", category: "EncryptionService")
        Logger.info("   Clé dérivée (premiers 16 bytes hex): \(keyHex)", category: "EncryptionService")
        Logger.info("   Taille de la clé: \(keyBytes.count) bytes (attendu: 32 bytes pour AES-256)", category: "EncryptionService")
        
        // Comparer avec la clé actuelle
        let currentKey = getEncryptionKey()
        let currentKeyBytes = currentKey.withUnsafeBytes { Data($0) }
        
        if keyBytes == currentKeyBytes {
            Logger.success("✅ [EncryptionService] Clé dérivée correcte", category: "EncryptionService")
        } else {
            Logger.error("❌ [EncryptionService] Clé dérivée incorrecte !", category: "EncryptionService")
            Logger.error("   Attendu: \(keyHex)", category: "EncryptionService")
            let currentKeyHex = currentKeyBytes.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " ")
            Logger.error("   Actuel: \(currentKeyHex)", category: "EncryptionService")
        }
    }
    
    // MARK: - Chiffrement
    
    /// Chiffre des données avec AES-GCM
    /// - Parameter data: Les données à chiffrer
    /// - Returns: Les données chiffrées avec le nonce préfixé, ou nil en cas d'erreur
    static func encrypt(_ data: Data) -> Data? {
        // MDRI Modification: Désactivation du chiffrement sur demande (17/01/2025)
        // On retourne les données en clair directement
        Logger.info("Chiffrement désactivé - retour des données en clair", category: "EncryptionService")
        return data
        
        /* Code original désactivé
        let key = getEncryptionKey()
        
        do {
            // Générer un nonce unique pour chaque chiffrement
            let nonce = AES.GCM.Nonce()
            
            // Chiffrer les données
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            
            // Combiner le nonce et les données chiffrées
            // Format: [nonce (12 bytes)][ciphertext + tag (16 bytes)]
            guard let encryptedData = sealedBox.combined else {
                Logger.error("Impossible de combiner les données chiffrées", category: "EncryptionService")
                return nil
            }
            
            return encryptedData
        } catch {
            Logger.error("Erreur lors du chiffrement: \(error.localizedDescription)", category: "EncryptionService")
            return nil
        }
        */
    }
    
    /// Déchiffre des données avec AES-GCM
    /// - Parameter encryptedData: Les données chiffrées (avec nonce préfixé)
    /// - Returns: Les données déchiffrées ou nil en cas d'erreur
    static func decrypt(_ encryptedData: Data) -> Data? {
        // MDRI Modification: Support des données en clair (17/01/2025)
        // Vérifier d'abord si les données sont chiffrées
        if !isEncrypted(encryptedData) {
            Logger.info("Données non chiffrées détectées, retour direct", category: "EncryptionService")
            return encryptedData
        }
        
        let key = getEncryptionKey()
        
        // Vérifier la taille minimale
        guard encryptedData.count >= 28 else {
            // Si c'est trop court et pas détecté comme chiffré, c'est peut-être juste un petit fichier texte/json
            // On tente de le retourner tel quel
            if let _ = String(data: encryptedData, encoding: .utf8) {
                Logger.info("Petit fichier texte détecté, retour direct", category: "EncryptionService")
                return encryptedData
            }
            
            Logger.error("Données trop courtes pour être déchiffrées (\(encryptedData.count) bytes < 28 bytes minimum)", category: "EncryptionService")
            return nil
        }
        
        // Logger les informations de diagnostic
        Logger.debug("🔍 [EncryptionService] Déchiffrement - Taille: \(encryptedData.count) bytes", category: "EncryptionService")
        
        // Extraire le nonce (12 premiers bytes)
        let nonceData = encryptedData.prefix(12)
        let nonceHex = nonceData.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " ")
        Logger.debug("   Nonce extrait: \(nonceData.count) bytes (hex: \(nonceHex)...)", category: "EncryptionService")
        
        // Extraire le tag (16 derniers bytes)
        let tagData = encryptedData.suffix(16)
        let tagHex = tagData.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " ")
        Logger.debug("   Tag extrait: \(tagData.count) bytes (hex: \(tagHex)...)", category: "EncryptionService")
        
        // Extraire le ciphertext (entre nonce et tag)
        let ciphertextData = encryptedData.dropFirst(12).dropLast(16)
        Logger.debug("   Ciphertext extrait: \(ciphertextData.count) bytes", category: "EncryptionService")
        
        // Logger la clé dérivée (premiers bytes pour vérification)
        let keyData = key.withUnsafeBytes { Data($0) }
        let keyHex = keyData.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " ")
        Logger.debug("   Clé dérivée: \(keyData.count) bytes (premiers bytes hex: \(keyHex)...)", category: "EncryptionService")
        
        // Logger le secret utilisé (partiellement masqué)
        let orgSecret = getOrganizationSecret()
        let maskedSecret = orgSecret.count > 8 ? 
            "\(orgSecret.prefix(4))...\(orgSecret.suffix(4))" : 
            "***"
        Logger.debug("   Secret organisationnel: \(maskedSecret) (longueur: \(orgSecret.count) caractères)", category: "EncryptionService")
        
        do {
            // Le format est: [nonce (12 bytes)][ciphertext + tag (16 bytes)]
            // Format exact du backend Web: nonce (12) + ciphertext + tag (16)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            
            // Déchiffrer les données
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            Logger.success("✅ [EncryptionService] Déchiffrement réussi (\(encryptedData.count) bytes → \(decryptedData.count) bytes)", category: "EncryptionService")
            return decryptedData
        } catch let error as CryptoKitError {
            Logger.error("❌ [EncryptionService] Erreur CryptoKit lors du déchiffrement: \(error.localizedDescription) (code: \(error))", category: "EncryptionService")
            
            // Logger plus de détails pour diagnostic
            let hexPreview = encryptedData.prefix(50).map { String(format: "%02x", $0) }.joined(separator: " ")
            Logger.debug("   Aperçu hexadécimal (50 premiers bytes): \(hexPreview)", category: "EncryptionService")
            Logger.debug("   Taille totale: \(encryptedData.count) bytes", category: "EncryptionService")
            
            // Vérifier si c'est un problème de clé
            if case .authenticationFailure = error {
                Logger.error("   ⚠️ Erreur d'authentification GCM - La clé de déchiffrement est probablement incorrecte", category: "EncryptionService")
                Logger.error("   Vérifiez que le secret organisationnel iOS correspond au backend Web", category: "EncryptionService")
            }
            
            return nil
        } catch {
            Logger.error("❌ [EncryptionService] Erreur lors du déchiffrement: \(error.localizedDescription)", category: "EncryptionService")
            return nil
        }
    }
    
    /// Vérifie si des données sont chiffrées (détection automatique)
    /// - Parameter data: Les données à vérifier
    /// - Returns: true si les données semblent être chiffrées
    static func isEncrypted(_ data: Data) -> Bool {
        // Les données chiffrées avec AES-GCM ont au moins 12 bytes (nonce) + 16 bytes (tag) = 28 bytes minimum
        guard data.count >= 28 else {
            Logger.debug("Données trop courtes pour être chiffrées (\(data.count) bytes < 28 bytes)", category: "EncryptionService")
            return false
        }
        
        // Tenter de parser comme JSON UTF-8 pour détecter si c'est du texte clair
        // Si c'est du JSON valide, ce n'est probablement pas chiffré
        if let text = String(data: data, encoding: .utf8),
           (text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") || text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[")),
           (try? JSONSerialization.jsonObject(with: data)) != nil {
            Logger.debug("Données détectées comme JSON valide (non chiffré)", category: "EncryptionService")
            return false
        }
        
        // Si ce n'est pas du JSON valide et que la taille est suffisante, probablement chiffré
        // Vérifier aussi que ce n'est pas du texte UTF-8 valide qui commence par autre chose que '{'
        if let text = String(data: data, encoding: .utf8),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") && !text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[") {
            // C'est du texte mais pas du JSON, probablement chiffré
            Logger.debug("Données détectées comme probablement chiffrées (texte non-JSON, \(data.count) bytes)", category: "EncryptionService")
            return true
        }
        
        // Si ce n'est pas du texte UTF-8 valide, c'est probablement du binaire chiffré
        if String(data: data, encoding: .utf8) == nil {
            Logger.debug("Données détectées comme probablement chiffrées (binaire, \(data.count) bytes)", category: "EncryptionService")
            return true
        }
        
        // Par défaut, considérer comme chiffré si la taille est suffisante
        Logger.debug("Données détectées comme probablement chiffrées (taille: \(data.count) bytes)", category: "EncryptionService")
        return true
    }
    
    // MARK: - Chiffrement avec Métadonnées Signées
    
    /// Chiffre des données avec métadonnées signées HMAC-SHA256
    /// Format: [4 bytes: longueur métadonnées][N bytes: JSON métadonnées][32 bytes: signature HMAC][M bytes: données chiffrées]
    /// - Parameters:
    ///   - data: Données à chiffrer
    ///   - metadata: Métadonnées à inclure (version, date, device, etc.)
    /// - Returns: Données chiffrées avec métadonnées ou nil en cas d'erreur
    static func encryptWithMetadata(_ data: Data, metadata: [String: String] = [:]) -> Data? {
        // 1. Préparer les métadonnées avec valeurs par défaut
        var finalMetadata = metadata
        if finalMetadata["version"] == nil {
            finalMetadata["version"] = "2.1"
        }
        if finalMetadata["encrypted_at"] == nil {
            finalMetadata["encrypted_at"] = ISO8601DateFormatter().string(from: Date())
        }
        if finalMetadata["checksum"] == nil {
            // Calculer SHA256 des données
            let hash = SHA256.hash(data: data)
            finalMetadata["checksum"] = "sha256:\(hash.compactMap { String(format: "%02x", $0) }.joined())"
        }
        
        // 2. Encoder les métadonnées en JSON
        guard let metadataJSON = try? JSONSerialization.data(withJSONObject: finalMetadata),
              metadataJSON.count < UInt32.max else {
            Logger.error("Impossible d'encoder les métadonnées", category: "EncryptionService")
            return nil
        }
        
        // 3. Calculer la signature HMAC-SHA256 des métadonnées
        let key = getEncryptionKey()
        let hmac = HMAC<SHA256>.authenticationCode(for: metadataJSON, using: key)
        let hmacData = Data(hmac)
        
        // 4. Chiffrer les données
        guard let encryptedData = encrypt(data) else {
            return nil
        }
        
        // 5. Assembler le tout: [length][metadata][hmac][encrypted]
        var result = Data()
        
        // Longueur des métadonnées (4 bytes, big endian)
        var length = UInt32(metadataJSON.count).bigEndian
        result.append(Data(bytes: &length, count: 4))
        
        // Métadonnées JSON
        result.append(metadataJSON)
        
        // Signature HMAC (32 bytes)
        result.append(hmacData)
        
        // Données chiffrées
        result.append(encryptedData)
        
        Logger.success("Données chiffrées avec métadonnées signées (\(result.count) bytes)", category: "EncryptionService")
        return result
    }
    
    /// Déchiffre des données avec vérification des métadonnées signées
    /// - Parameter encryptedData: Données chiffrées avec métadonnées
    /// - Returns: Tuple (données déchiffrées, métadonnées) ou nil en cas d'erreur
    static func decryptWithMetadata(_ encryptedData: Data) -> (data: Data, metadata: [String: String])? {
        // 1. Vérifier la taille minimale
        guard encryptedData.count > 4 + 32 + 28 else { // 4 (length) + 32 (HMAC) + 28 (min AES-GCM)
            Logger.error("Données trop courtes pour contenir des métadonnées", category: "EncryptionService")
            return nil
        }
        
        // 2. Extraire la longueur des métadonnées
        let lengthData = encryptedData.prefix(4)
        let length = UInt32(bigEndian: lengthData.withUnsafeBytes { $0.load(as: UInt32.self) })
        
        guard Int(length) + 4 + 32 < encryptedData.count else {
            Logger.error("Longueur de métadonnées invalide", category: "EncryptionService")
            return nil
        }
        
        // 3. Extraire les métadonnées
        let metadataStart = 4
        let metadataEnd = metadataStart + Int(length)
        let metadataJSON = encryptedData.subdata(in: metadataStart..<metadataEnd)
        
        // 4. Extraire la signature HMAC
        let hmacStart = metadataEnd
        let hmacEnd = hmacStart + 32
        let storedHMAC = encryptedData.subdata(in: hmacStart..<hmacEnd)
        
        // 5. Vérifier la signature
        let key = getEncryptionKey()
        let computedHMAC = HMAC<SHA256>.authenticationCode(for: metadataJSON, using: key)
        
        guard Data(computedHMAC) == storedHMAC else {
            Logger.error("Signature HMAC invalide - données potentiellement corrompues", category: "EncryptionService")
            return nil
        }
        
        // 6. Décoder les métadonnées
        guard let metadata = try? JSONSerialization.jsonObject(with: metadataJSON) as? [String: String] else {
            Logger.error("Impossible de décoder les métadonnées JSON", category: "EncryptionService")
            return nil
        }
        
        // 7. Extraire et déchiffrer les données
        let encryptedPayload = encryptedData.subdata(in: hmacEnd..<encryptedData.count)
        guard let decryptedData = decrypt(encryptedPayload) else {
            return nil
        }
        
        // 8. Vérifier le checksum si présent
        if let checksum = metadata["checksum"], checksum.starts(with: "sha256:") {
            let hash = SHA256.hash(data: decryptedData)
            let computedChecksum = "sha256:\(hash.compactMap { String(format: "%02x", $0) }.joined())"
            
            guard checksum == computedChecksum else {
                Logger.error("Checksum invalide - données corrompues", category: "EncryptionService")
                return nil
            }
        }
        
        Logger.success("Données déchiffrées et vérifiées avec succès", category: "EncryptionService")
        return (data: decryptedData, metadata: metadata)
    }
}

