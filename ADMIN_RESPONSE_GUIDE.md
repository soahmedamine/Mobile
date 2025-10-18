# Guide: Comment Répondre aux Réclamations en tant qu'Admin 🔧

## ✅ Problème Résolu
L'admin peut maintenant **répondre aux réclamations** en cliquant sur une réclamation et en utilisant le bouton **"Respond to Reclamation"**.

## 🔐 Identifiants Admin

Pour tester la fonctionnalité admin, utilisez ces identifiants :

**Email:** `youssef.oueslati@esprit.tn`  
**Password:** `admin123`

## 📝 Comment Répondre à une Réclamation (Admin)

### Étape 1: Se Connecter en tant qu'Admin
1. Lancez l'application
2. Sur l'écran de login, entrez :
   - Email: `youssef.oueslati@esprit.tn`
   - Password: `admin123`
3. Cliquez sur **LOGIN**

### Étape 2: Accéder aux Réclamations
1. Dans le menu (drawer), cliquez sur **"View Reclamations"** ou **"Réclamations"**
2. Vous verrez **TOUTES** les réclamations de tous les utilisateurs

### Étape 3: Répondre à une Réclamation
1. **Cliquez** sur une réclamation dans la liste
2. Vous verrez l'écran de détails avec toutes les informations
3. En bas de l'écran, vous verrez le bouton bleu : **"Respond to Reclamation"**
4. Cliquez sur ce bouton
5. Sur l'écran Admin Response :
   - Changez le **statut** (New / In Progress / Resolved)
   - Entrez votre **réponse** dans le champ texte
   - Cliquez sur **"Save Response"**

### Étape 4: Vérifier la Réponse
1. Retournez à la liste des réclamations
2. La réclamation devrait maintenant avoir le nouveau statut
3. L'utilisateur pourra voir votre réponse

## 🎯 Fonctionnalités Admin

### Dans l'écran de détails (ReclamationDetailScreen)
- ✅ Voir tous les détails de la réclamation
- ✅ Voir les pièces jointes (si présentes)
- ✅ Bouton **"Respond to Reclamation"** (visible uniquement pour admin)

### Dans l'écran de réponse (AdminResponseScreen)
- ✅ Modifier le statut (new → in_progress → resolved)
- ✅ Ajouter/modifier une réponse
- ✅ Voir l'historique de la réclamation
- ✅ Validation : la réponse doit contenir au moins 10 caractères

## 🔄 Workflow Complet

### Pour l'Utilisateur
1. Créer une réclamation (statut: **new**)
2. Attendre la réponse de l'admin
3. Voir la réponse et le statut mis à jour

### Pour l'Admin
1. Se connecter avec le compte admin
2. Voir toutes les réclamations
3. Cliquer sur une réclamation → **"Respond to Reclamation"**
4. Changer le statut à **"in_progress"**
5. Écrire une réponse
6. Sauvegarder
7. Plus tard : changer le statut à **"resolved"**

## 🐛 Debugging

Si le bouton **"Respond to Reclamation"** ne s'affiche pas :

### Vérifier le rôle
```dart
// Dans la console Flutter, vous devriez voir :
✅ SharedPreferences initialized
User role: admin
_isAdmin: true
```

### Forcer le reload du rôle
1. Déconnectez-vous de l'application
2. Reconnectez-vous avec les identifiants admin
3. Vérifiez dans SharedPreferences :
```dart
final prefs = await SharedPreferences.getInstance();
print('User role: ${prefs.getString('user_role')}');
```

### Si le problème persiste
1. Supprimez l'application complètement
2. Réinstallez-la
3. Connectez-vous avec le compte admin

## 📊 Structure de la Base de Données

Les réclamations sont maintenant stockées dans **SQLite** :
- Toutes les réclamations sont dans la même base
- Visibles par tous les admins
- L'utilisateur normal ne voit que ses propres réclamations
- L'admin voit **TOUTES** les réclamations

## 🎨 Interface Utilisateur

### Bouton "Respond to Reclamation"
- **Couleur:** Bleu primaire
- **Icône:** 📝 (edit_note)
- **Position:** En bas de l'écran de détails
- **Visibilité:** Admin uniquement

### Écran Admin Response
- **Segmented Button** pour le statut (New / In Progress / Resolved)
- **TextFormField** pour la réponse (min 10 caractères)
- **Bouton Save** en haut à droite ET en bas

## ✨ Améliorations Apportées

1. ✅ Ajout du bouton "Respond to Reclamation" dans `ReclamationDetailScreen`
2. ✅ Vérification automatique du rôle admin
3. ✅ Navigation vers `AdminResponseScreen`
4. ✅ Retour automatique après sauvegarde
5. ✅ Rechargement de la liste après mise à jour
6. ✅ Base de données SQLite unifiée
7. ✅ Migration automatique des données

## 🚀 Pour Tester Immédiatement

1. Hot reload ou hot restart l'app
2. Login avec : `youssef.oueslati@esprit.tn` / `admin123`
3. Allez dans "View Reclamations"
4. Cliquez sur n'importe quelle réclamation
5. Scrollez en bas → Vous verrez le bouton bleu **"Respond to Reclamation"**
6. Cliquez et testez !

## 📞 Support

Si vous avez toujours des problèmes :
- Vérifiez les logs Flutter pour les erreurs
- Assurez-vous d'être connecté en tant qu'admin
- Vérifiez que `user_role` = `'admin'` dans SharedPreferences
