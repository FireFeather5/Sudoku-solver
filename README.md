# Solveur de sudoku

## Description

**Projet universitaire**

Solveur de sudoku créé en MIPS32, capable de retourner la ou les solution(s) de remplissage d'une grille passée dans un fichier texte.

## Technologies utilisées

**Langage :** Assembleur (MIPS 32)

**Application :** Mars

## Installation

Cloner le repo :
```bash
git clone https://github.com/FireFeather5/Sudoku-solver
```
Ou télécharger tous les fichiers à la main.

### Utilisation avec [Mars](https://github.com/dpetersanderson/MARS)

Pour modifier la grille de sudoku à résoudre, modifier le fichier `grille.txt` avec une grille valable (des exemples de grilles sont disponibles au début du fichier `SudokuSolver.asm`).

Lancer l'application Mars dans le même répertoire :
```bash
java -jar 'nom application'
```

Ouvrir le fichier `SudokuSolver.asm` dans Mars.

Lancer le fichier depuis l'application et attendre la fin de l'exécution.

> [!NOTE]  
> L'exécution peut prendre du temps en fonction du nombre de solutions

## Fonctionnalités

### Le solveur est codé récursivement

Il teste toutes les possibilités, et retourne toutes les solutions de remplissages correctes. Il continue tant que toutes les possibilités n'ont pas été testées pour s'assurer de n'en manquer aucune. Si il n'y a pas de solution de remplissage, le programme l'indique par un affichage.

### Lecture dans un fichier texte

La grille à résoudre se trouve dans un fichier texte à part, ce qui rend la modification plus rapide.
