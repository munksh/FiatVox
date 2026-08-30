Name:       harbour-fiatvox
Summary:    Chromatic tuner
Version:    1.0.0
Release:    1
License:    MIT
URL:        https://github.com/munksh/FiatVox
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  desktop-file-utils

%description
A chromatic tuner that listens continuously. One letter, seven dots, and the
frequency in hertz. No controls.

%if 0%{?_chum}
Title: fiat vox
Type: desktop-application
DeveloperName: Munkstolen
Categories:
 - AudioVideo
 - Audio
 - Utility
Custom:
  Repo: https://github.com/munksh/FiatVox
  PackagingRepo: https://github.com/munksh/FiatVox
Icon: https://munkstolen.se/SFOS/fiat-vox/harbour-fiatvox.png
Screenshots:
 - https://munkstolen.se/SFOS/fiat-vox/fiat-vox1.png
 - https://munkstolen.se/SFOS/fiat-vox/fiat-vox2.png
 - https://munkstolen.se/SFOS/fiat-vox/fiat-vox3.png
Url:
  Homepage: https://munkstolen.se
  Help: https://github.com/munksh/FiatVox/issues
  Bugtracker: https://github.com/munksh/FiatVox/issues
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
%make_build

%install
%qmake5_install
desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
  %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Sun Aug 30 2026 Caesar Ivarsson <caesar@munkstolen.se> - 1.0.0-1
- First release.
