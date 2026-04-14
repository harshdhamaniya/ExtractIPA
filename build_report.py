#!/usr/bin/env python3
"""
ExtractIPA Build Configuration Generator
Analyzes project and creates build report
"""

import os
import json
from pathlib import Path
from datetime import datetime

class BuildReportGenerator:
    def __init__(self, project_dir='.'):
        self.project_dir = Path(project_dir)
        self.report = {
            'timestamp': datetime.now().isoformat(),
            'project': 'ExtractIPA',
            'platform': 'iOS',
            'files': {},
            'build_info': {},
            'recommendations': []
        }

    def analyze_project(self):
        """Analyze project structure and files"""
        print("🔍 Analyzing ExtractIPA project structure...")

        # Check Swift files
        swift_files = list(self.project_dir.glob('*.swift'))
        self.report['files']['swift'] = {
            'count': len(swift_files),
            'files': [f.name for f in swift_files],
            'size_kb': sum(f.stat().st_size for f in swift_files) / 1024
        }

        # Check documentation
        md_files = list(self.project_dir.glob('*.md'))
        self.report['files']['documentation'] = {
            'count': len(md_files),
            'files': [f.name for f in md_files]
        }

        # Check configuration
        config_files = {
            'plist': list(self.project_dir.glob('*.plist')),
            'entitlements': list(self.project_dir.glob('*.entitlements')),
            'swift_package': list(self.project_dir.glob('Package.swift')),
            'build_scripts': list(self.project_dir.glob('*.sh'))
        }

        for config_type, files in config_files.items():
            self.report['files'][config_type] = {
                'count': len(files),
                'files': [f.name for f in files]
            }

    def analyze_build_readiness(self):
        """Check if project is ready for building"""
        print("📋 Checking build readiness...\n")

        checks = {
            'Swift source files': len(list(self.project_dir.glob('*.swift'))) >= 5,
            'Info.plist': (self.project_dir / 'Info.plist').exists(),
            'Entitlements file': (self.project_dir / 'ExtractIPA.entitlements').exists(),
            'Build script': (self.project_dir / 'build.sh').exists(),
            'GitHub Actions workflow': (self.project_dir / '.github/workflows/build.yml').exists(),
            'Package.swift': (self.project_dir / 'Package.swift').exists(),
            'Dockerfile': (self.project_dir / 'Dockerfile').exists(),
            'README.md': (self.project_dir / 'README.md').exists(),
            'SETUP.md': (self.project_dir / 'SETUP.md').exists(),
            'BUILD.md': (self.project_dir / 'BUILD.md').exists(),
        }

        self.report['build_info']['readiness_checks'] = checks
        self.report['build_info']['ready_for_build'] = all(checks.values())

    def generate_recommendations(self):
        """Generate build recommendations"""
        print("💡 Generating recommendations...\n")

        recommendations = []

        # Check macOS requirement
        recommendations.append({
            'type': 'REQUIREMENT',
            'message': '✅ iOS builds require macOS 12.0+ with Xcode 14.0+',
            'action': 'If on Windows, use: GitHub Actions (cloud build) or remote Mac via SSH'
        })

        # Check Swift files
        swift_count = len(list(self.project_dir.glob('*.swift')))
        if swift_count >= 5:
            recommendations.append({
                'type': 'INFO',
                'message': f'✅ Found {swift_count} Swift source files',
                'status': 'READY'
            })
        else:
            recommendations.append({
                'type': 'WARNING',
                'message': f'⚠️ Only {swift_count} Swift files found (expecting 7+)',
                'action': 'Add missing implementation files'
            })

        # Check entitlements
        if (self.project_dir / 'ExtractIPA.entitlements').exists():
            recommendations.append({
                'type': 'INFO',
                'message': '✅ Entitlements file configured for jailbreak',
                'note': 'Will require signing with private Apple certificates or ldid'
            })

        # Build methods
        recommendations.append({
            'type': 'BUILD_OPTIONS',
            'methods': [
                '1️⃣ Direct Xcode (fastest, Mac only)',
                '2️⃣ Command line with xcodebuild',
                '3️⃣ Automated build.sh script',
                '4️⃣ GitHub Actions (cloud, no Mac needed)',
                '5️⃣ Docker container',
                '6️⃣ Remote Mac via SSH'
            ]
        })

        # File organization
        if (self.project_dir / 'Sources').exists():
            recommendations.append({
                'type': 'INFO',
                'message': '✅ Sources directory properly organized'
            })
        else:
            recommendations.append({
                'type': 'OPTIONAL',
                'message': 'Consider creating ./Sources/ directory for better organization'
            })

        self.report['recommendations'] = recommendations

    def print_report(self):
        """Print formatted report"""
        print("\n")
        print("=" * 60)
        print("   ExtractIPA Build Configuration Report")
        print("=" * 60)
        print()

        # Project Overview
        print("📱 PROJECT OVERVIEW")
        print("-" * 60)
        print(f"  Project Name:     {self.report['project']}")
        print(f"  Platform:         {self.report['platform']}")
        print(f"  Generated:        {self.report['timestamp']}")
        print()

        # File Summary
        print("📁 PROJECT FILES")
        print("-" * 60)
        for file_type, info in self.report['files'].items():
            if 'count' in info:
                print(f"  {file_type.upper():20} {info['count']:3} file(s)")
                if 'files' in info and info['count'] <= 5:
                    for fname in info['files'][:5]:
                        print(f"    • {fname}")
        print()

        # Build Readiness
        print("✅ BUILD READINESS CHECKLIST")
        print("-" * 60)
        checks = self.report['build_info'].get('readiness_checks', {})
        for check_name, passed in checks.items():
            status = "✓" if passed else "✗"
            print(f"  [{status}] {check_name}")

        overall = self.report['build_info'].get('ready_for_build', False)
        print()
        if overall:
            print("  🎉 PROJECT IS READY FOR BUILDING!")
        else:
            print("  ⚠️ Project needs some configuration before building")
        print()

        # Recommendations
        print("💡 RECOMMENDATIONS & BUILD OPTIONS")
        print("-" * 60)
        for rec in self.report['recommendations']:
            if rec['type'] == 'REQUIREMENT':
                print(f"  {rec['message']}")
                print(f"    → {rec['action']}")
            elif rec['type'] == 'BUILD_OPTIONS':
                print("  Available build methods:")
                for method in rec['methods']:
                    print(f"    {method}")
            elif rec['type'] in ['INFO', 'OPTIONAL', 'WARNING']:
                print(f"  {rec['message']}")
                if 'note' in rec:
                    print(f"    Note: {rec['note']}")
                if 'action' in rec:
                    print(f"    → {rec['action']}")
        print()

        # Next Steps
        print("🚀 NEXT STEPS")
        print("-" * 60)
        print("  1. Review BUILD.md for detailed build instructions")
        print("  2. Choose your build method:")
        print("     • Mac users: Run ./build.sh")
        print("     • Windows/Linux: Use GitHub Actions for cloud builds")
        print("  3. Or transfer to Mac and run: chmod +x build.sh && ./build.sh")
        print()
        print("=" * 60)

    def save_json_report(self, filename='build_report.json'):
        """Save detailed report as JSON"""
        filepath = self.project_dir / filename
        with open(filepath, 'w') as f:
            json.dump(self.report, f, indent=2)
        print(f"📝 Detailed report saved to: {filename}")

    def generate(self):
        """Run complete analysis"""
        self.analyze_project()
        self.analyze_build_readiness()
        self.generate_recommendations()
        self.print_report()
        self.save_json_report()

def main():
    import sys

    project_dir = sys.argv[1] if len(sys.argv) > 1 else '.'

    try:
        generator = BuildReportGenerator(project_dir)
        generator.generate()
        return 0
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1

if __name__ == '__main__':
    exit(main())
