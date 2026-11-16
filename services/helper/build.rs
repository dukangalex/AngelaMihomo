fn main() {
    let version = std::env::var("TOKEN").unwrap_or_default();
    let token_directive = ["cargo:rustc-env=TOKEN=", version.as_str()].concat();
    println!("{}", token_directive);
    println!("cargo:rerun-if-env-changed=TOKEN");

    // Executable names are injected by setup.dart from the same identity
    // source as the Dart side (AppIdentity). The defaults are the current
    // release names so a bare `cargo build` still produces a helper that
    // accepts the shipped app; never hardcode a stale product name here.
    let app_exe =
        std::env::var("APP_EXE_NAME").unwrap_or_else(|_| "AngelaMihomo.exe".to_string());
    println!("cargo:rustc-env=APP_EXE_NAME={}", app_exe);
    println!("cargo:rerun-if-env-changed=APP_EXE_NAME");

    let core_exe =
        std::env::var("CORE_EXE_NAME").unwrap_or_else(|_| "AngelaMihomoCore.exe".to_string());
    println!("cargo:rustc-env=CORE_EXE_NAME={}", core_exe);
    println!("cargo:rerun-if-env-changed=CORE_EXE_NAME");

    let dev_core_exe = std::env::var("DEV_CORE_EXE_NAME")
        .unwrap_or_else(|_| "AngelaMihomoDevCore.exe".to_string());
    println!("cargo:rustc-env=DEV_CORE_EXE_NAME={}", dev_core_exe);
    println!("cargo:rerun-if-env-changed=DEV_CORE_EXE_NAME");
}
