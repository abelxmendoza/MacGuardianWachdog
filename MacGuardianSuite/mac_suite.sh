#!/bin/bash

# Mac Guardian Suite Control Menu
# Interactive menu to run Mac Guardian tools

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for better UX
bold=$(tput bold 2>/dev/null || echo "")
normal=$(tput sgr0 2>/dev/null || echo "")
green=$(tput setaf 2 2>/dev/null || echo "")
red=$(tput setaf 1 2>/dev/null || echo "")

# Function to check if script exists and is executable
check_script() {
    local script="$1"
    if [ ! -f "$script" ]; then
        echo "${red}❌ Error: $script not found${normal}" >&2
        return 1
    fi
    chmod +x "$script"
    return 0
}

# Function to run a script with error handling
run_script() {
    local script="$1"
    local name="$2"
    
    if ! check_script "$script"; then
        return 1
    fi
    
    echo ""
    echo "${bold}${green}▶ Running $name...${normal}"
    echo "----------------------------------------"
    if ./"$(basename "$script")"; then
        echo ""
        echo "${green}✅ $name completed successfully${normal}"
        return 0
    else
        echo ""
        echo "${red}❌ $name encountered an error${normal}" >&2
        return 1
    fi
}

# Main menu loop
while true; do
    clear
    echo "${bold}=============================="
    echo "🧠 Mac Guardian Suite Control"
    echo "==============================${normal}"
    echo ""
    echo "1) Run Mac Guardian (Cleanup & Security)"
    echo "2) Run Mac Watchdog (File Integrity Monitor)"
    echo "3) Run Mac Blue Team (Advanced Threat Detection)"
    echo "4) Run Mac AI (Intelligent Security Analysis)"
    echo "5) Run Mac Security Audit (Comprehensive Security Assessment)"
    echo "6) Run Mac Remediation (Auto-Fix Security Issues)"
    echo "7) Run all (Guardian, Watchdog, Blue Team, AI, Audit)"
    echo "8) Verify Suite (Test All Components)"
    echo "9) View & Fix Errors (Error Database)"
    echo "10) Hardening Assessment (Security Evaluation)"
    echo "11) Generate Security Report"
    echo "12) Setup Phase 1 Features (Reports & Alerts)"
    echo "13) Test Email (Send Test Email)"
    echo "14) Performance Monitor (View Performance Stats)"
    echo "15) Advanced Reports (Comparisons, PDF Export)"
    echo "16) Exit"
    echo ""
    read -p "Select (1-16): " choice
    
    case "$choice" in
        1)
            if run_script "mac_guardian.sh" "Mac Guardian"; then
                read -p "Press Enter to continue..."
            else
                read -p "Press Enter to continue..."
            fi
            ;;
        2)
            if run_script "mac_watchdog.sh" "Mac Watchdog"; then
                read -p "Press Enter to continue..."
            else
                read -p "Press Enter to continue..."
            fi
            ;;
        3)
            run_script "mac_blueteam.sh" "Mac Blue Team"
            read -p "Press Enter to continue..."
            ;;
        4)
            run_script "mac_ai.sh" "Mac AI"
            read -p "Press Enter to continue..."
            ;;
        5)
            run_script "mac_security_audit.sh" "Mac Security Audit"
            read -p "Press Enter to continue..."
            ;;
        6)
            run_script "mac_remediation.sh" "Mac Remediation"
            read -p "Press Enter to continue..."
            ;;
        7)
            echo ""
            echo "${bold}Running all tools in sequence...${normal}"
            if run_script "mac_guardian.sh" "Mac Guardian"; then
                echo ""
                if run_script "mac_watchdog.sh" "Mac Watchdog"; then
                    echo ""
                    if run_script "mac_blueteam.sh" "Mac Blue Team"; then
                        echo ""
                        if run_script "mac_ai.sh" "Mac AI"; then
                            echo ""
                        if run_script "mac_security_audit.sh" "Mac Security Audit"; then
                            echo ""
                            echo "${cyan}💡 Tip: Run Remediation to auto-fix any issues found${normal}"
                            echo ""
                            read -p "Would you like to run Remediation now to auto-fix issues? (y/n): " run_remediation
                            if [[ "$run_remediation" =~ ^[Yy]$ ]]; then
                                echo ""
                                run_script "mac_remediation.sh" "Mac Remediation"
                            fi
                        fi
                        fi
                    fi
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        8)
            run_script "verify_suite.sh" "Suite Verification"
            read -p "Press Enter to continue..."
            ;;
        9)
            run_script "view_errors.sh" "Error Viewer & Fixer"
            read -p "Press Enter to continue..."
            ;;
        10)
            run_script "hardening_assessment.sh" "Hardening Assessment"
            read -p "Press Enter to continue..."
            ;;
        11)
            run_script "scheduled_reports.sh" "Security Report Generator"
            read -p "Press Enter to continue..."
            ;;
        12)
            run_script "setup_phase1_features.sh" "Phase 1 Features Setup"
            read -p "Press Enter to continue..."
            ;;
        13)
            run_script "test_email.sh" "Email Test"
            read -p "Press Enter to continue..."
            ;;
        14)
            if [ -f "performance_monitor.sh" ]; then
                echo ""
                echo "${bold}⚡ Performance Monitor${normal}"
                echo "----------------------------------------"
                ./performance_monitor.sh bottlenecks
                echo ""
                ./performance_monitor.sh suggestions
                echo ""
            else
                echo "${red}Performance monitor not found${normal}"
            fi
            read -p "Press Enter to continue..."
            ;;
        15)
            if [ -f "advanced_reporting.sh" ]; then
                echo ""
                echo "${bold}📊 Advanced Reporting${normal}"
                echo "----------------------------------------"
                echo "1) Generate Comparison Report"
                echo "2) Export Report to PDF"
                echo "3) Generate Executive Summary"
                echo "4) Create Custom Template"
                read -p "Select (1-4): " report_choice
                case "$report_choice" in
                    1)
                        latest_report=$(ls -t "$HOME/.macguardian/reports"/*.html 2>/dev/null | head -1)
                        if [ -n "$latest_report" ]; then
                            ./advanced_reporting.sh compare "$latest_report"
                        else
                            echo "${red}No reports found. Generate a report first.${normal}"
                        fi
                        ;;
                    2)
                        latest_report=$(ls -t "$HOME/.macguardian/reports"/*.html 2>/dev/null | head -1)
                        if [ -n "$latest_report" ]; then
                            ./advanced_reporting.sh pdf "$latest_report"
                        else
                            echo "${red}No reports found. Generate a report first.${normal}"
                        fi
                        ;;
                    3)
                        ./advanced_reporting.sh executive
                        ;;
                    4)
                        ./advanced_reporting.sh template
                        ;;
                esac
            else
                echo "${red}Advanced reporting not found${normal}"
            fi
            read -p "Press Enter to continue..."
            ;;
        16)
            echo ""
            echo "${green}👋 Goodbye! Stay secure!${normal}"
            exit 0
            ;;
        *)
            echo "${red}❌ Invalid option. Please select 1-16.${normal}"
            sleep 2
            ;;
    esac
done

