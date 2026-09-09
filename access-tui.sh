#!/usr/bin/env bash
# ==============================================================================
# key :: clean, fast SSH access setup
# Bulletproof numeric deletion & rock-solid navigation
# ==============================================================================

cleanup() {
  printf "\033[?25h"
  stty sane 2>/dev/null || stty echo icanon 2>/dev/null || true
}
trap cleanup EXIT INT TERM

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_CYAN="\033[38;2;56;189;248m"
C_GREEN="\033[38;2;52;211;153m"
C_GRAY="\033[38;2;148;163;184m"
C_MUTED="\033[38;2;100;116;139m"
C_WARN="\033[38;2;251;191;36m"
C_ERR="\033[38;2;248;113;113m"

declare -a PRESETS=(
  'Personal|contact.mijanur80@gmail.com|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOhFnsZEj3hobSCHPKM5nBe5pe5JpMBZLkclhs/4tbsq contact.mijanur80@gmail.com'
  'Office Windows Key|azuread\mijanurrahman@DESKTOP-GU545GC|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDr0NzVQIXILM0AN/Fq6sJQDzylZBteK4blpGvrYzOi azuread\mijanurrahman@DESKTOP-GU545GC'
  'iOS|root@localhost|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDIuCvdGaodeKgn9cRLndpx8s4uuJ9qV11bsHF4aJ1XF root@localhost'
)

AUTH_FILE="$HOME/.ssh/authorized_keys"
SSHD_CONFIG="/etc/ssh/sshd_config"

ensure_ssh() {
  # 1. Ensure user home directory is not group/world writable (required by sshd StrictModes)
  if [[ -d "$HOME" ]]; then
    chmod 755 "$HOME" 2>/dev/null || chmod 700 "$HOME" 2>/dev/null || true
  fi

  # 2. Ensure .ssh directory exists with strict 700 permissions
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh" 2>/dev/null || true

  # 3. Ensure authorized_keys exists with strict 600 permissions
  touch "$AUTH_FILE"
  chmod 600 "$AUTH_FILE" 2>/dev/null || true

  # 4. Ensure ownership belongs to current user
  if [[ $(id -u) -eq 0 ]]; then
    chown -R root:root "$HOME/.ssh" 2>/dev/null || true
  else
    local cur_user cur_grp
    cur_user=$(id -un 2>/dev/null || whoami)
    cur_grp=$(id -gn 2>/dev/null || id -un 2>/dev/null || whoami)
    chown -R "$cur_user:$cur_grp" "$HOME/.ssh" 2>/dev/null || true
  fi

  # 5. If running as root, ensure sshd allows PubkeyAuthentication and authorized_keys
  if [[ $(id -u) -eq 0 && -f "$SSHD_CONFIG" ]]; then
    local reload_needed=0
    # Ensure PubkeyAuthentication is yes
    if grep -qE '^[#[:space:]]*PubkeyAuthentication[[:space:]]+no' "$SSHD_CONFIG"; then
      sed -i 's/^[#[:space:]]*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
      reload_needed=1
    elif ! grep -qE '^[[:space:]]*PubkeyAuthentication[[:space:]]+yes' "$SSHD_CONFIG"; then
      echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
      reload_needed=1
    fi

    # Ensure /etc/ssh/sshd_config.d doesn't disable pubkey
    if [[ -d /etc/ssh/sshd_config.d ]]; then
      for f in /etc/ssh/sshd_config.d/*.conf; do
        if [[ -f "$f" ]] && grep -qE '^[[:space:]]*PubkeyAuthentication[[:space:]]+no' "$f"; then
          sed -i 's/^[[:space:]]*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$f"
          reload_needed=1
        fi
      done
    fi

    if [[ $reload_needed -eq 1 ]]; then
      systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || service ssh reload 2>/dev/null || true
    fi
  fi
}

count_keys() {
  if [[ -f "$AUTH_FILE" ]]; then
    grep -c -v '^[[:space:]]*$' "$AUTH_FILE" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

add_key() {
  local k="$1"
  local label="${2:-Key}"
  ensure_ssh
  # Trim leading/trailing whitespace without xargs (which strips backslashes)
  k="${k#"${k%%[![:space:]]*}"}"
  k="${k%"${k##*[![:space:]]}"}"
  if [[ -z "$k" ]]; then return 1; fi

  if grep -qF "$k" "$AUTH_FILE" 2>/dev/null; then
    printf "  ${C_GRAY}[*] %s is already installed${C_RESET}\n" "$label"
  else
    printf "%s\n" "$k" >> "$AUTH_FILE"
    chmod 600 "$AUTH_FILE"
    printf "  ${C_GREEN}[+] %s installed successfully${C_RESET}\n" "$label"
  fi
}

read_nav_key() {
  local input=""
  IFS= read -rs -n1 input < /dev/tty 2>/dev/null || IFS= read -rs -n1 input 2>/dev/null || return 1

  if [[ "$input" == $'\x1b' ]]; then
    local char1="" char2=""
    read -rs -n1 -t 0.05 char1 < /dev/tty 2>/dev/null || read -rs -n1 -t 0.05 char1 2>/dev/null || true
    read -rs -n1 -t 0.05 char2 < /dev/tty 2>/dev/null || read -rs -n1 -t 0.05 char2 2>/dev/null || true
    input+="${char1}${char2}"

    if [[ "$input" == *"[A"* || "$input" == *"OA"* ]]; then
      echo "UP"; return 0
    elif [[ "$input" == *"[B"* || "$input" == *"OB"* ]]; then
      echo "DOWN"; return 0
    else
      echo "ESC"; return 0
    fi
  fi

  case "$input" in
    k|K) echo "UP" ;;
    j|J) echo "DOWN" ;;
    "")  echo "ENTER" ;;
    q|Q) echo "QUIT" ;;
    *)   echo "$input" ;;
  esac
}

# ------------------------------------------------------------------------------
# Screen: Custom Public Key (Instant Esc or q to go back)
# ------------------------------------------------------------------------------
custom_key_screen() {
  clear
  printf "\n  ${C_CYAN}${C_BOLD}key${C_RESET} ${C_MUTED}:: paste custom public key${C_RESET}\n\n"
  printf "  ${C_GRAY}Paste your public key (e.g. ssh-ed25519 ... or ssh-rsa ...)${C_RESET}\n"
  printf "  ${C_MUTED}[Esc / q] Go back   [Enter on empty] Cancel${C_RESET}\n\n"
  printf "  ${C_CYAN}> ${C_RESET}"

  local first_char=""
  stty -echo -icanon 2>/dev/null || true
  IFS= read -rs -n1 first_char < /dev/tty 2>/dev/null || IFS= read -rs -n1 first_char 2>/dev/null || true
  stty echo icanon 2>/dev/null || true

  if [[ "$first_char" == $'\x1b' || "$first_char" == "q" || "$first_char" == "Q" || "$first_char" == "" ]]; then
    printf "${C_MUTED}(Cancelled)${C_RESET}\n"
    sleep 0.4
    return 0
  fi

  printf "%s" "$first_char"
  local rest_of_line=""
  IFS= read -r rest_of_line < /dev/tty 2>/dev/null || IFS= read -r rest_of_line || true
  local custom_key="${first_char}${rest_of_line}"
  custom_key=$(echo "$custom_key" | xargs)

  if [[ -z "$custom_key" || "$custom_key" == "q" || "$custom_key" == "exit" ]]; then
    printf "\n  ${C_MUTED}Cancelled.${C_RESET}\n"
    sleep 0.4
    return 0
  fi

  printf "\n"
  if [[ ! "$custom_key" =~ ^(ssh-|ecdsa-) ]]; then
    printf "  ${C_WARN}! Warning: String doesn't start with standard SSH prefix (ssh-* / ecdsa-*)${C_RESET}\n"
  fi

  add_key "$custom_key" "Custom key"
  printf "\n  ${C_MUTED}Press Enter to continue...${C_RESET}"
  read -r _ < /dev/tty 2>/dev/null || read -r _
}

# ------------------------------------------------------------------------------
# Password Authentication Screen
# ------------------------------------------------------------------------------
password_auth_screen() {
  if [[ $(id -u) -ne 0 ]]; then
    clear
    printf "\n  ${C_CYAN}${C_BOLD}key${C_RESET} ${C_MUTED}:: password authentication${C_RESET}\n\n"
    printf "  ${C_WARN}! Root/sudo privileges required to edit /etc/ssh/sshd_config${C_RESET}\n"
    printf "  ${C_MUTED}Please run this command with sudo:${C_RESET}\n"
    printf "  ${C_BOLD}sudo bash <(curl -fsSL https://raw.githubusercontent.com/mijanlab/key/main/access-tui.sh)${C_RESET}\n\n"
    printf "  ${C_MUTED}Press Enter to return...${C_RESET}"
    read -r _ < /dev/tty 2>/dev/null || read -r _
    return 0
  fi

  if [[ ! -f "$SSHD_CONFIG" ]]; then
    clear
    printf "\n  ${C_CYAN}${C_BOLD}key${C_RESET} ${C_MUTED}:: password authentication${C_RESET}\n\n"
    printf "  ${C_ERR}? $SSHD_CONFIG not found on this system.${C_RESET}\n\n"
    printf "  ${C_MUTED}Press Enter to return...${C_RESET}"
    read -r _ < /dev/tty 2>/dev/null || read -r _
    return 0
  fi

  local cursor=0
  local options=(
    "Disable password authentication (keys only)"
    "Enable password authentication (yes)"
    "Back to main menu"
  )
  local total=${#options[@]}

  while true; do
    stty -echo -icanon 2>/dev/null || true

    local current_pass
    current_pass=$(grep -E '^[[:space:]]*PasswordAuthentication' "$SSHD_CONFIG" | tail -n1 | awk '{print $2}' || echo "default")
    if [[ -z "$current_pass" ]]; then current_pass="default (yes)"; fi

    printf "\033[H\033[2J\033[?25l"
    printf "\n  ${C_CYAN}${C_BOLD}key${C_RESET} ${C_MUTED}:: password authentication settings${C_RESET}\n"
    printf "  ${C_GRAY}Current status: ${C_BOLD}%s${C_RESET}\n\n" "$current_pass"

    for i in "${!options[@]}"; do
      if [[ $i -eq $cursor ]]; then
        printf "  ${C_CYAN}${C_BOLD}> %s${C_RESET}\n" "${options[$i]}"
      else
        printf "    ${C_GRAY}%s${C_RESET}\n" "${options[$i]}"
      fi
    done

    printf "\n  ${C_MUTED}[UP/DOWN or j/k or 1-%d] Navigate   [Enter] Apply   [Esc/q] Back${C_RESET}\n" "$total"

    local key
    key=$(read_nav_key)

    case "$key" in
      UP)
        if [[ $cursor -gt 0 ]]; then ((cursor--)); else cursor=$((total - 1)); fi
        ;;
      DOWN)
        if [[ $cursor -lt $((total - 1)) ]]; then ((cursor++)); else cursor=0; fi
        ;;
      1) cursor=0 ;;
      2) cursor=1 ;;
      3) cursor=2 ;;
      ENTER)
        stty echo icanon 2>/dev/null || true
        printf "\033[?25h\n"
        if [[ $cursor -eq 2 ]]; then
          return 0
        fi

        cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%s)"

        if [[ $cursor -eq 0 ]]; then
          if [[ $(count_keys) -eq 0 ]]; then
            printf "  ${C_ERR}[!] SAFETY WARNING: You have 0 installed SSH keys!${C_RESET}\n"
            printf "  ${C_ERR}Disabling password login now would lock you out of the server.${C_RESET}\n"
            printf "  ${C_MUTED}Please install an SSH key first before disabling passwords.${C_RESET}\n\n"
            printf "  ${C_MUTED}Press Enter to continue...${C_RESET}"
            read -r _ < /dev/tty 2>/dev/null || read -r _
            continue
          fi

          # Update main sshd_config
          sed -i 's/^[#[:space:]]*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
          grep -q "^PasswordAuthentication" "$SSHD_CONFIG" || echo "PasswordAuthentication no" >> "$SSHD_CONFIG"
          sed -i 's/^[#[:space:]]*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' "$SSHD_CONFIG" 2>/dev/null || true
          sed -i 's/^[#[:space:]]*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD_CONFIG" 2>/dev/null || true
          sed -i 's/^[#[:space:]]*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
          grep -q "^PubkeyAuthentication" "$SSHD_CONFIG" || echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"

          # Also update any drop-in files in /etc/ssh/sshd_config.d/ (e.g. cloud-init)
          if [[ -d /etc/ssh/sshd_config.d ]]; then
            for conf in /etc/ssh/sshd_config.d/*.conf; do
              if [[ -f "$conf" ]]; then
                sed -i 's/^[#[:space:]]*PasswordAuthentication.*/PasswordAuthentication no/' "$conf" 2>/dev/null || true
                sed -i 's/^[#[:space:]]*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' "$conf" 2>/dev/null || true
              fi
            done
          fi

          printf "  ${C_GREEN}[+] Password authentication disabled (key-only enforced)${C_RESET}\n"
        elif [[ $cursor -eq 1 ]]; then
          sed -i 's/^[#[:space:]]*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
          grep -q "^PasswordAuthentication" "$SSHD_CONFIG" || echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
          if [[ -d /etc/ssh/sshd_config.d ]]; then
            for conf in /etc/ssh/sshd_config.d/*.conf; do
              if [[ -f "$conf" ]]; then
                sed -i 's/^[#[:space:]]*PasswordAuthentication.*/PasswordAuthentication yes/' "$conf" 2>/dev/null || true
              fi
            done
          fi
          printf "  ${C_GREEN}[+] Password authentication enabled${C_RESET}\n"
        fi

        systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || service ssh reload 2>/dev/null || true
        printf "  ${C_GREEN}[+] SSH service reloaded successfully${C_RESET}\n\n"
        printf "  ${C_MUTED}Press Enter to continue...${C_RESET}"
        read -r _ < /dev/tty 2>/dev/null || read -r _
        ;;
      ESC|QUIT)
        stty echo icanon 2>/dev/null || true
        return 0
        ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# Screen: Select Preconfigured Key
# ------------------------------------------------------------------------------
select_preset_screen() {
  local cursor=0
  local total=${#PRESETS[@]}

  while true; do
    stty -echo -icanon 2>/dev/null || true
    printf "\033[H\033[2J\033[?25l"
    printf "\n  ${C_CYAN}${C_BOLD}key${C_RESET} ${C_MUTED}:: select preconfigured key${C_RESET}\n\n"

    for i in "${!PRESETS[@]}"; do
      IFS='|' read -r name comment kdata <<< "${PRESETS[$i]}"
      if [[ $i -eq $cursor ]]; then
        printf "  ${C_CYAN}${C_BOLD}> %-10s${C_RESET} ${C_MUTED}(%s)${C_RESET}\n" "$name" "$comment"
      else
        printf "    ${C_GRAY}%-10s${C_RESET} ${C_MUTED}(%s)${C_RESET}\n" "$name" "$comment"
      fi
    done

    printf "\n  ${C_MUTED}[UP/DOWN or j/k or 1-%d] Navigate   [Enter] Install   [Esc/q] Back${C_RESET}\n" "$total"

    local key
    key=$(read_nav_key)
    case "$key" in
      UP)
        if [[ $cursor -gt 0 ]]; then ((cursor--)); else cursor=$((total - 1)); fi
        ;;
      DOWN)
        if [[ $cursor -lt $((total - 1)) ]]; then ((cursor++)); else cursor=0; fi
        ;;
      [1-3])
        cursor=$((key - 1))
        ;;
      ENTER)
        stty echo icanon 2>/dev/null || true
        printf "\033[?25h\n"
        local sel="${PRESETS[$cursor]}"
        IFS='|' read -r name comment kdata <<< "$sel"
        add_key "$kdata" "$name"
        printf "\n  ${C_MUTED}Press Enter to continue...${C_RESET}"
        read -r _ < /dev/tty 2>/dev/null || read -r _
        return 0
        ;;
      ESC|QUIT)
        stty echo icanon 2>/dev/null || true
        return 0
        ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# Screen: Delete Key (Fast, simple number-input method)
# ------------------------------------------------------------------------------
delete_key_screen() {
  while true; do
    declare -a CURRENT_KEYS=()
    if [[ -s "$AUTH_FILE" ]]; then
      while IFS= read -r line; do
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
          CURRENT_KEYS+=("$line")
        fi
      done < "$AUTH_FILE"
    fi

    local total=${#CURRENT_KEYS[@]}
    if [[ $total -eq 0 ]]; then
      printf "\033[H\033[2J\033[?25h"
      printf "\n  ${C_CYAN}${C_BOLD}key${C_RESET} ${C_MUTED}:: delete authorized key${C_RESET}\n\n"
      printf "  ${C_MUTED}(No active keys found in authorized_keys)${C_RESET}\n\n"
      printf "  ${C_MUTED}Press Enter to return...${C_RESET}"
      read -r _ < /dev/tty 2>/dev/null || read -r _
      return 0
    fi

    stty echo icanon 2>/dev/null || true
    printf "\033[H\033[2J\033[?25h"
    printf "\n  ${C_CYAN}${C_BOLD}key${C_RESET} ${C_MUTED}:: choose key to delete${C_RESET}\n\n"

    for i in "${!CURRENT_KEYS[@]}"; do
      local line="${CURRENT_KEYS[$i]}"
      local ktype
      ktype=$(echo "$line" | awk '{print $1}')
      local kcomment
      kcomment=$(echo "$line" | awk '{print $3}')
      if [[ -z "$kcomment" ]]; then kcomment="no comment"; fi

      printf "  ${C_CYAN}%2d)${C_RESET} %-12s ${C_MUTED}%s${C_RESET}\n" $((i+1)) "$ktype" "$kcomment"
    done

    printf "\n  ${C_MUTED}Enter key number to delete [1-%d] (or 0/q to cancel):${C_RESET} " "$total"
    local del_idx=""
    read -r del_idx < /dev/tty 2>/dev/null || read -r del_idx

    if [[ -z "$del_idx" || "$del_idx" == "0" || "$del_idx" == "q" || "$del_idx" == "Q" ]]; then
      return 0
    fi

    if [[ "$del_idx" =~ ^[0-9]+$ && "$del_idx" -ge 1 && "$del_idx" -le "$total" ]]; then
      local target_key="${CURRENT_KEYS[$((del_idx-1))]}"
      local target_comment
      target_comment=$(printf "%s" "$target_key" | awk '{print $3}')
      if [[ -z "$target_comment" ]]; then target_comment="Selected key"; fi

      printf "\n  ${C_WARN}Are you sure you want to remove '%s'? [y/N]:${C_RESET} " "$target_comment"
      local confirm=""
      read -r confirm < /dev/tty 2>/dev/null || read -r confirm

      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        local tmp_file
        tmp_file=$(mktemp)
        grep -v -F "$target_key" "$AUTH_FILE" > "$tmp_file" || true
        cat "$tmp_file" > "$AUTH_FILE"
        rm -f "$tmp_file"
        chmod 600 "$AUTH_FILE"
        printf "\n  ${C_GREEN}[+] Key removed successfully${C_RESET}\n"
      else
        printf "\n  ${C_MUTED}Cancelled${C_RESET}\n"
      fi

      printf "\n  ${C_MUTED}Press Enter to continue...${C_RESET}"
      read -r _ < /dev/tty 2>/dev/null || read -r _
    else
      printf "\n  ${C_ERR}! Invalid number. Please enter a number between 1 and %d.${C_RESET}\n" "$total"
      sleep 1
    fi
  done
}

# ------------------------------------------------------------------------------
# Screen: View Keys
# ------------------------------------------------------------------------------
view_keys_screen() {
  while true; do
    printf "\033[H\033[2J\033[?25h"
    printf "\n  ${C_CYAN}${C_BOLD}key${C_RESET} ${C_MUTED}:: active authorized keys${C_RESET}\n"
    printf "  ${C_GRAY}%s${C_RESET}\n\n" "$AUTH_FILE"

    if [[ -s "$AUTH_FILE" ]]; then
      local num=1
      while IFS= read -r line; do
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
          local ktype
          ktype=$(echo "$line" | awk '{print $1}')
          local kcomment
          kcomment=$(echo "$line" | awk '{print $3}')
          printf "  ${C_CYAN}%2d.${C_RESET} %-12s ${C_MUTED}%s${C_RESET}\n" "$num" "$ktype" "${kcomment:-no comment}"
          ((num++))
        fi
      done < "$AUTH_FILE"
    else
      printf "  ${C_MUTED}(No authorized keys found)${C_RESET}\n"
    fi

    printf "\n  ${C_CYAN}d${C_RESET}  Delete a key (enter number)\n"
    printf "  ${C_CYAN}0 / Esc / q${C_RESET}  Back to main menu\n\n"
    printf "  ${C_MUTED}Option [d/0]:${C_RESET} "

    stty -echo -icanon 2>/dev/null || true
    local opt_key
    opt_key=$(read_nav_key)
    stty echo icanon 2>/dev/null || true

    case "$opt_key" in
      d|D)
        delete_key_screen
        ;;
      0|QUIT|ESC|ENTER)
        return 0
        ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# Main Menu
# ------------------------------------------------------------------------------
declare -a MAIN_OPTIONS=(
  "Install all preconfigured keys"
  "Select preconfigured key"
  "Paste custom public key"
  "View active keys (with delete option)"
  "Password authentication settings"
  "Exit"
)

main() {
  local cursor=0
  local total=${#MAIN_OPTIONS[@]}

  while true; do
    stty -echo -icanon 2>/dev/null || true
    printf "\033[H\033[2J\033[?25l"
    printf "\n  ${C_CYAN}${C_BOLD}key${C_RESET} ${C_MUTED}:: server access setup${C_RESET}\n"
    printf "  ${C_GRAY}%s@%s${C_RESET} ${C_MUTED}-- %s active key(s)${C_RESET}\n\n" \
      "$(whoami)" "$(hostname -s 2>/dev/null || echo 'server')" "$(count_keys)"

    for i in "${!MAIN_OPTIONS[@]}"; do
      if [[ $i -eq $cursor ]]; then
        printf "  ${C_CYAN}${C_BOLD}> %s${C_RESET}\n" "${MAIN_OPTIONS[$i]}"
      else
        printf "    ${C_GRAY}%s${C_RESET}\n" "${MAIN_OPTIONS[$i]}"
      fi
    done

    printf "\n  ${C_MUTED}[UP/DOWN or j/k or 1-%d] Navigate   [Enter] Select   [Esc/q] Quit${C_RESET}\n" "$total"

    local key
    key=$(read_nav_key)

    case "$key" in
      UP)
        if [[ $cursor -gt 0 ]]; then ((cursor--)); else cursor=$((total - 1)); fi
        ;;
      DOWN)
        if [[ $cursor -lt $((total - 1)) ]]; then ((cursor++)); else cursor=0; fi
        ;;
      1) cursor=0 ;;
      2) cursor=1 ;;
      3) cursor=2 ;;
      4) cursor=3 ;;
      5) cursor=4 ;;
      6) cursor=5 ;;
      ENTER)
        stty echo icanon 2>/dev/null || true
        printf "\033[?25h"
        case "$cursor" in
          0)
            printf "\n"
            for item in "${PRESETS[@]}"; do
              IFS='|' read -r name comment kdata <<< "$item"
              add_key "$kdata" "$name"
            done
            printf "\n  ${C_MUTED}Press Enter to continue...${C_RESET}"
            read -r _ < /dev/tty 2>/dev/null || read -r _
            ;;
          1)
            select_preset_screen
            ;;
          2)
            custom_key_screen
            ;;
          3)
            view_keys_screen
            ;;
          4)
            password_auth_screen
            ;;
          5)
            printf "\n  ${C_MUTED}Bye!${C_RESET}\n\n"
            exit 0
            ;;
        esac
        ;;
      QUIT|ESC)
        stty echo icanon 2>/dev/null || true
        printf "\033[?25h\n  ${C_MUTED}Bye!${C_RESET}\n\n"
        exit 0
        ;;
    esac
  done
}

main "$@"
