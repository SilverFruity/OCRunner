int fibonaccia(int n){
    if (n == 1 || n == 2)
        return 1;
    return fibonaccia(n - 1) + fibonaccia(n - 2);
}
int a = fibonaccia(25);
