# ViyaOcToolBox 🔨

Une collection d'outils en ligne de commande basés sur PowerShell pour interagir avec un environnement SAS Viya 4 hébergé sur un cluster OpenShift.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![OpenShift](https://img.shields.io/badge/OpenShift-4.x-red.svg)
![SAS Viya](https://img.shields.io/badge/SAS%20Viya-4-brightgreen.svg)

## 🎯 À propos du projet

`ViyaOcToolBox` a été créé pour simplifier la gestion et la surveillance des pods d'une plateforme SAS Viya 4 qui s'exécute sur un cluster Red Hat OpenShift. Face à la complexité des commandes `oc` et `kubectl`, ces outils offrent des raccourcis et des interfaces interactives pour les tâches courantes d'administration et de dépannage.

Ce projet utilise des scripts PowerShell, appelés via des fichiers `.bat`, pour se connecter à un namespace spécifique et effectuer des actions comme lister des pods, afficher leurs logs ou encore obtenir des descriptions détaillées pour le débogage.

## ✨ Fonctionnalités

* **Listage simple des pods :** Obtenez rapidement la liste de tous les pods SAS Viya en cours d'exécution dans votre namespace.
* **Mode interactif :** Naviguez facilement dans la liste des pods pour sélectionner celui qui vous intéresse.
* **Accès rapide aux logs :** Affichez les logs d'un pod spécifique sans avoir à taper de longues commandes.
* **Description détaillée des pods :** Accédez à la sortie de `oc describe` pour un pod choisi, essentielle pour le diagnostic des problèmes.
* **Simplicité d'utilisation :** Lancez les outils avec de simples fichiers `.bat` depuis votre terminal Windows.

## 🚀 Prérequis

Avant de commencer, assurez-vous d'avoir les éléments suivants installés et configurés sur votre machine :

* **PowerShell 5.1 ou supérieur.**
* **L'outil en ligne de commande OpenShift (`oc.exe`)** : Il doit être présent dans le `PATH` de votre système pour que les scripts puissent l'appeler. Vous pouvez le télécharger depuis la console web de votre cluster OpenShift (`?` > `Command Line Tools`).
* **Accès à un cluster OpenShift :** Vous devez être authentifié auprès de votre cluster via la commande `oc login`.
