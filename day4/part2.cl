bool check_pin(int pin) {
    bool has_double = false;
    int double_group = 0;
    while(pin > 0) {
        int currDigit = pin % 10;
        int prevDigit = (pin = pin / 10) % 10;

        if (prevDigit > currDigit) return false;
        if(!has_double) {
            if (prevDigit == currDigit) double_group++;
            else if (double_group == 1) has_double = true;
            else double_group = 0;
        }
    }

    return has_double;
}

__kernel void check_all_pins(__global const int *a_g, __global int *res_g) {
    int i = get_global_id(0);
    int pin = a_g[i];

    if (check_pin(pin)) res_g[i] = 1;
    else res_g[i] = 0;
}