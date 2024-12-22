%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern FILE *yyin;
int yylex(void);  // Declare yylex
void yyerror(const char *s);  // Declare yyerror
void evaluate_answer(char *user_answer, char *correct_answer, int points);

int score = 0;
int difficulty_threshold = 1;
%}

%union {
    char *str;  // For strings
    int num;    // For numbers
}

%token QUIZ QUESTION TYPE OPTIONS CORRECT THRESHOLD
%token TRUE_FALSE MCQ NUMERIC FILL_IN_BLANK
%token <str> STRING
%token <num> NUMBER

%type <num> question_type
%type <str> answer options

%%

quiz            : QUIZ STRING THRESHOLD NUMBER question_list {
                    difficulty_threshold = $4;
                    printf("Quiz: %s, Difficulty Threshold: %d\n", $2, difficulty_threshold);
                }
                ;

question_list   : question_list question
                | question
                ;

question        : QUESTION STRING TYPE question_type options CORRECT answer {
                    if ($4 == 1) {
                        printf("Question (True/False): %s\n", $2);
                    } else if ($4 == 2) {
                        printf("Question (MCQ): %s\n", $2);
                        printf("Options: %s\n", $5);
                    } else if ($4 == 3) {
                        printf("Question (Numeric): %s\n", $2);
                    } else if ($4 == 4) {
                        printf("Question (Fill in the Blank): %s\n", $2);  // Handle fill-in-the-blank
                    }

                    char user_answer[100];
                    printf("Your Answer: ");
                    fgets(user_answer, sizeof(user_answer), stdin); // Read input with spaces
                    evaluate_answer(user_answer, $7, $4);
                }
                ;

question_type   : TRUE_FALSE              { $$ = 1; /* Easy */ }
                | MCQ                     { $$ = 2; /* Medium */ }
                | NUMERIC                 { $$ = 3; /* Hard */ }
                | FILL_IN_BLANK           { $$ = 4; /* Blank */ }
                ;

options         : OPTIONS STRING STRING STRING STRING {
                    char options_combined[200];
                    snprintf(options_combined, sizeof(options_combined), "%s, %s, %s, %s", $2, $3, $4, $5);
                    $$ = strdup(options_combined);  // Store options as a string
                }
                | /* Empty */ { $$ = strdup(""); }
                ;

answer          : STRING                  { $$ = $1; }
                | NUMBER                  {
                    char buffer[20];
                    sprintf(buffer, "%d", $1);
                    $$ = strdup(buffer);
                }
                ;

%%

void evaluate_answer(char *user_answer, char *correct_answer, int points) {
    // Trim trailing newline character from user_answer
    size_t len = strlen(user_answer);
    if (len > 0 && user_answer[len - 1] == '\n') {
        user_answer[len - 1] = '\0';
    }

    // Compare answers case-insensitively
    if (strcasecmp(user_answer, correct_answer) == 0) {
        score += points;
        printf("Correct! You earned %d points.\n", points);
    } else {
        printf("Incorrect. Correct answer is: %s\n", correct_answer);
        if (points >= difficulty_threshold) {
            printf("Tip: Focus more on this type of question.\n");
        }
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    FILE *file = fopen("quiz_input.txt", "r");  // Open the quiz input file
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    yyin = file;  // Redirect Lex input to the file

    printf("Welcome to the Personalized Quiz Evaluator!\n");

    // Parse the quiz file
    if (yyparse() == 0) {
        printf("Quiz parsed successfully!\n");
    } else {
        printf("Error parsing the quiz file.\n");
        fclose(file);
        return 1;
    }

    fclose(file);  // Close the file after parsing

    printf("Final score: %d\n", score);
    return 0;
}
