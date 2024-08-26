#! /bin/bash

# Define log file
LOG_FILE="./number_guessing_game.log"

# Redirect stdout and stderr to log file
exec > >(tee -a $LOG_FILE) 2>&1

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

DISPLAY() {
  echo -e "\n~~~~~ Number Guessing Game ~~~~~\n" 

echo "Enter your username:"
read USERNAME

#get username from db
  USER_ID=$($PSQL "select u_id from users where name = '$USERNAME'")


  if [[ $USER_ID ]]; then
  # User found, fetch user data
    GAMES_PLAYED=$($PSQL "select count(u_id) from games where u_id = '$USER_ID'")

    #get best game (guess)
    BEST_GUESS=$($PSQL "select min(guesses) from games where u_id = '$USER_ID'")

    echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GUESS guesses."
  else
  # User not found, welcome new user
    echo "\nWelcome, $USERNAME! It looks like this is your first time here."

    #insert to users table
    INSERTED_TO_USERS=$($PSQL "insert into users(name) values('$USERNAME')")
    #get user_id
    USER_ID=$($PSQL "select u_id from users where name = '$USERNAME'")
    # echo $USER_ID
  fi

  GAME
}

GAME() {

  # Generate a random number
min=1
max=1000
SECRET=$(( RANDOM % (max - min + 1) + min ))

echo "Guess the secret number between 1 and 1000:"

GUESSED=0


  while [[ $GUESSED = 0 ]]; do
    read GUESS

    #if not a number
    if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
      echo -e "\nThat is not an integer, guess again:"
    #if correct guess
    elif [[ $SECRET = $GUESS ]]; then
      TRIES=$(($TRIES + 1))
      echo -e "\nYou guessed it in $TRIES tries. The secret number was $SECRET. Nice job!"
      #insert into db
      INSERTED_TO_GAMES=$($PSQL "insert into games(u_id, guesses) values($USER_ID, $TRIES)")
      GUESSED=1
    #if greater
    elif [[ $SECRET -gt $GUESS ]]; then
      TRIES=$(($TRIES + 1))
      echo -e "\nIt's higher than that, guess again:"
    #if smaller
    else
      TRIES=$(($TRIES + 1))
      echo -e "\nIt's lower than that, guess again:"
    fi
  done

}

DISPLAY