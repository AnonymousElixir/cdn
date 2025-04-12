tmp_script=$(mktemp) && curl -fsSL -o "$tmp_script" https://raw.githubusercontent.com/AnonymousElixir/cdn/refs/heads/main/qb.sh && chmod +x "$tmp_script" && bash "$tmp_script" && rm "$tmp_script"
