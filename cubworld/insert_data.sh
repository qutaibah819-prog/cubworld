#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# تفريغ الجداول وإعادة تصفير عداد الـ SERIAL إلى رقم 1 لمنع الأخطاء وتكرار البيانات
echo "$($PSQL "TRUNCATE games, teams RESTART IDENTITY;")"

# قراءة ملف الـ CSV سطر بسطر وتحديد الأعمدة بالفواصل
cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # تخطي السطر الأول الذي يحتوي على عناوين الأعمدة
  if [[ $YEAR != "year" ]]
  then
    # 1. التعامل مع الفريق الفائز (Winner)
    # جلب المعرف الخاص بالفريق من قاعدة البيانات
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    
    # إذا لم يتم العثور على المعرف (الفريق غير موجود)
    if [[ -z $WINNER_ID ]]
    then
      # إدخال الفريق الجديد في جدول الفرق
      INSERT_WINNER_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$WINNER')")
      if [[ $INSERT_WINNER_RESULT == "INSERT 0 1" ]]
      then
        echo "Inserted into teams: $WINNER"
      fi
      # جلب المعرف الجديد بعد الإدخال
      WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    fi

    # 2. التعامل مع الفريق الخصم (Opponent)
    # جلب المعرف الخاص بالفريق من قاعدة البيانات
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    
    # إذا لم يتم العثور على المعرف (الفريق غير موجود)
    if [[ -z $OPPONENT_ID ]]
    then
      # إدخال الفريق الجديد في جدول الفرق
      INSERT_OPPONENT_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$OPPONENT')")
      if [[ $INSERT_OPPONENT_RESULT == "INSERT 0 1" ]]
      then
        echo "Inserted into teams: $OPPONENT"
      fi
      # جلب المعرف الجديد بعد الإدخال
      OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    fi

    # 3. إدخال بيانات المباراة في جدول المباريات (Games)
    INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)")
    if [[ $INSERT_GAME_RESULT == "INSERT 0 1" ]]
    then
      echo "Inserted into games: $YEAR $ROUND - $WINNER vs $OPPONENT"
    fi

  fi
done
