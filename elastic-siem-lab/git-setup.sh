#!/bin/bash
# HOW TO PUSH THIS PROJECT TO GITHUB
# Run these commands from inside the elastic-siem-lab/ folder

# -------------------------------------------------------
# ONE-TIME SETUP (if you haven't configured git before)
# -------------------------------------------------------
git config --global user.name "Your Name"
git config --global user.email "you@email.com"

# -------------------------------------------------------
# INITIALIZE AND PUSH
# -------------------------------------------------------

# 1. Initialize git in the project folder
git init

# 2. Stage all files
git add .

# 3. First commit
git commit -m "Initial commit: Elastic SIEM lab documentation"

# 4. Create the repo on GitHub first (go to github.com → New Repository)
#    Name it: elastic-siem-lab
#    Set it to Public
#    DO NOT initialize with README (you already have one)

# 5. Link your local repo to GitHub (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/elastic-siem-lab.git

# 6. Push
git branch -M main
git push -u origin main

# -------------------------------------------------------
# FUTURE UPDATES (add screenshots, new configs, etc.)
# -------------------------------------------------------
# git add .
# git commit -m "Add Kibana dashboard screenshots"
# git push
