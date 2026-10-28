# SILVER FEVER · Héléana's 30th Birthday

Samedi 30 janvier 2027, 19 h · Bar Le Surnaturel, 6 rue Poincaré, Mulhouse.
Réponses attendues avant le 13 décembre 2026.

## Ce que contient ce dépôt

| Fichier | Rôle |
|---|---|
| `index.html` | Le site des invités (tout en un seul fichier) |
| `admin.html` | L'espace privé d'Héléana : réponses, liste des invités, réglages |
| `silver-fever.sql` | La base de données à installer dans Supabase |
| `og.jpg` | L'image d'aperçu affichée quand on partage le lien (WhatsApp, SMS…) |
| `robots.txt` | Demande aux moteurs de recherche de ne pas référencer le site |

Comment ça marche :
- **Le site** est hébergé gratuitement par GitHub Pages, en HTTPS.
- **Les réponses** sont enregistrées dans Supabase (projet `silver-fever`).
  Les invités ne peuvent rien y lire : ils passent par trois fonctions qui
  vérifient le code d'invitation et ne renvoient jamais de nom de famille,
  d'e-mail, d'allergie, de petit mot ni de réponse négative.
- **Héléana** consulte tout sur `admin.html`, après connexion par e-mail et
  mot de passe. En plus, chaque réponse lui est envoyée par mail (Formspree).

---

## Mise en ligne (une seule fois)

### 1. Installer la base de données
Supabase > projet `silver-fever` > **SQL Editor** > New query : coller tout
`silver-fever.sql`, cliquer sur **Run**. Le message attendu est « Success ».
Le script peut être relancé sans risque.

### 2. Créer le compte d'Héléana
1. Supabase > **Authentication** > **Users** > **Add user** > *Create new user* :
   son e-mail, un mot de passe solide, cocher **Auto Confirm User**.
2. SQL Editor, lancer cette ligne avec son adresse :
   `insert into public.sf_admins (email) values (lower('son@adresse.fr'));`
3. Authentication > **Sign In / Providers** : désactiver
   **Allow new users to sign up**.

### 3. Activer le site
Sur GitHub, dépôt `silver-fever` > **Settings** > **Pages** :
Source « Deploy from a branch », branche `main`, dossier `/ (root)`, **Save**.
Le site est en ligne en une à deux minutes sur
`https://evadigiu.github.io/silver-fever/`.

### 4. Changer le code d'invitation (important)
Le code de départ, `SILVER30`, est écrit dans `silver-fever.sql`, qui est
visible publiquement sur GitHub. Avant d'envoyer le lien :
ouvrir `https://evadigiu.github.io/silver-fever/admin.html`, se connecter,
**Réglages du site** > Code d'invitation > en choisir un nouveau
(ex. `DISCO-HEL-7Q`) > **Enregistrer**.

### 5. Ajouter la liste des invités
Dans `admin.html` > **Ajouter des invités** : un invité par ligne, prénom puis
nom. C'est ce qui permet de voir **qui n'a pas encore répondu**.

### 6. Tester, puis envoyer
Copier le **lien à envoyer aux invités** (dans les réglages). Il contient le
code : les invités n'ont rien à taper. Faire une réponse de test depuis un
téléphone, vérifier qu'elle apparaît dans `admin.html` et que le mail arrive,
puis la supprimer.

---

## Au quotidien

**Consulter les réponses** : `admin.html`. Les tuiles en haut (Viennent, Ne
viennent pas, Sans réponse, Hors liste) filtrent la liste d'un clic. Filtres
« Allergies » et « Petits mots » pour la logistique. Bouton **Exporter (CSV)**
pour ouvrir le tout dans Excel.

**« Hors liste »** = quelqu'un a répondu avec un nom qui ne correspond à
personne de la liste (surnom, faute de frappe, +1). Le bouton « Ajouter à la
liste » le rattache. Les accents, majuscules et tirets sont ignorés dans la
comparaison : « jean marc muller » = « Jean-Marc Müller ».

**Changer d'avis** : un invité qui répond à nouveau avec les mêmes prénom et
nom remplace sa réponse précédente.

**Guest list publique** (réglages) : nombre seul (par défaut), nombre +
prénoms des invités qui ont coché l'accord, ou section masquée.

**Connecter la playlist** : dans `index.html`, en haut du script, remplir
`playlistUrl` avec le lien de partage de la playlist (Spotify, Deezer, Apple
Music…). Le bouton « Écouter la playlist » apparaît alors ; pour un lien
Spotify, un lecteur intégré s'ajoute aussi (il ne démarre jamais tout seul).
Tant que le lien est vide, le site affiche « La playlist officielle arrive
bientôt » et les invités peuvent proposer des morceaux.

**Modifier un texte** : tous les textes sont dans `index.html`, lisibles en
clair. Les dates, l'adresse de l'agenda et les liens sont regroupés en haut
du script (`const CONFIG`). Après modification sur GitHub, le site se met à
jour en une à deux minutes.

**Mails de notification** : `formspreeId` dans `CONFIG`. Mettre `""` pour ne
plus en recevoir. Le quota gratuit de Formspree est limité (autour de 50
envois par mois) : au-delà, les mails s'arrêtent, mais les réponses restent
bien enregistrées dans Supabase.

---

## Confidentialité : ce qui est protégé, et ce qui ne l'est pas

- Protégé : les réponses, e-mails, allergies et petits mots ne sont lisibles
  que depuis `admin.html` par un compte déclaré dans `sf_admins`.
- Protégé : sans le bon code, personne ne peut répondre, proposer un son ni
  voir la guest list. Le code bloque aussi les robots.
- **Pas protégé** : les textes du site (date, lieu, adresse) sont visibles par
  toute personne qui a le lien, comme sur un carton d'invitation. GitHub
  Pages ne permet pas de mettre un mot de passe sur la page elle-même. Le
  site demande aux moteurs de recherche de ne pas le référencer.
- Une personne qui connaît le code et le nom exact d'un invité pourrait
  modifier sa réponse. Dans un cercle de proches, le risque est faible.

**Supabase gratuit se met en pause après 7 jours sans visite.** Le site
affiche alors un message d'erreur clair au moment de répondre, et rien n'est
perdu : Supabase > projet > **Restore project**. Y jeter un œil au moment de
l'envoi des invitations et la semaine du 13 décembre.

**Après la fête** : effacer les données au plus tard fin février 2027
(bouton en bas d'`admin.html`).
