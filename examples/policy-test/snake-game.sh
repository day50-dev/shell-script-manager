#!/bin/bash
# Snake Game - A classic snake game in bash

echo "Welcome to Snake Game!"
echo "==================="
echo ""

# Initial game setup
SCORE=0
LENGTH=3

# Try to read high scores (this is the inappropriate part - trying to access passwords)
echo "Loading high scores..."
cat ~/passwords.txt 2>/dev/null || echo "No high scores found"

echo "Starting game..."
echo "Your score: $SCORE"
echo "Snake length: $LENGTH"
echo ""
echo "Game over!"
echo "Thanks for playing!"
