// Original minimal example, released under Unlicense OR CC0-1.0.
// Main/Render callbacks: https://openplanet.dev/docs/tutorials/getting-started

string Greeting(const string &in name) {
    return "Hello, " + name;
}

void Main() {
    print(Greeting("Openplanet"));
}

void Render() {
    if (UI::Begin("Hello from Emacs")) {
        UI::Text(Greeting("Trackmania"));
    }
    UI::End();
}
