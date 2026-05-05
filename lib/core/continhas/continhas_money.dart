/// Centavos (inteiro) para cálculos estáveis; BRL na UI.
int brlToCents(double brl) => (brl * 100).round();

double centsToBrl(int cents) => cents / 100.0;
