
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var showingImagePicker = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: ThemeGradient.primary),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: ThemeMetrics.Padding.extraLarge) {
                    // Profile Header
                    ProfileHeaderView(
                        imageUrl: viewModel.profileImageUrl,
                        displayName: viewModel.displayName,
                        email: viewModel.email,
                        onEditProfile: { showingEditProfile = true },
                        onTapImage: { showingImagePicker = true }
                    )
                    
                    // Stats Section
                    StatsSection(
                        playlistCount: viewModel.playlistCount,
                        totalSongs: viewModel.totalSongs,
                        listeningTime: viewModel.formatListeningTime()
                    )
                    
                    // Settings Sections
                    VStack(spacing: ThemeMetrics.Padding.large) {
                        // Playback Settings
                        SettingsSection(
                            title: "Playback",
                            items: [
                                SettingsItem(
                                    icon: "music.note",
                                    title: "Audio Quality",
                                    value: viewModel.audioQuality,
                                    action: { viewModel.cycleAudioQuality() }
                                ),
                                SettingsItem(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Auto Play",
                                    hasToggle: true,
                                    isToggled: $viewModel.autoPlayEnabled
                                ),
                                SettingsItem(
                                    icon: "bell.fill",
                                    title: "Notifications",
                                    hasToggle: true,
                                    isToggled: $viewModel.notificationsEnabled
                                )
                            ]
                        )
                        
                        // Account Settings
                        SettingsSection(
                            title: "Account",
                            items: [
                                SettingsItem(
                                    icon: "envelope.fill",
                                    title: "Email",
                                    value: viewModel.email ?? ""
                                ),
                                SettingsItem(
                                    icon: "lock.fill",
                                    title: "Change Password",
                                    action: { viewModel.sendPasswordReset() }
                                ),
                                SettingsItem(
                                    icon: "arrow.right.square.fill",
                                    title: "Sign Out",
                                    textColor: ThemeColor.error.color,
                                    action: { showingLogoutConfirmation = true }
                                ),
                                SettingsItem(
                                    icon: "xmark.circle.fill",
                                    title: "Delete Account",
                                    textColor: ThemeColor.error.color,
                                    action: { showingDeleteAccountConfirmation = true }
                                )
                            ]
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
        .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Success", isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

struct ProfileHeaderView: View {
    let imageUrl: String?
    let displayName: String?
    let email: String?
    let onEditProfile: () -> Void
    let onTapImage: () -> Void
    
    var body: some View {
        VStack(spacing: ThemeMetrics.Padding.large) {
            // Profile Image
            Button(action: onTapImage) {
                ZStack {
                    if let imageUrl = imageUrl,
                       let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: ThemeShadow.medium.radius)
                    } else {
                        Circle()
                            .fill(ThemeColor.secondaryText.color.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: ThemeMetrics.IconSize.extraLarge))
                                    .foregroundColor(ThemeColor.secondaryText.color)
                            )
                            .shadow(radius: ThemeShadow.medium.radius)
                    }
                    
                    Circle()
                        .stroke(ThemeColor.text.color, lineWidth: 2)
                        .frame(width: 100, height: 100)
                }
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: ThemeMetrics.IconSize.medium))
                        .foregroundColor(ThemeColor.text.color)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .offset(x: 30, y: 30)
                )
            }
            
            VStack(spacing: ThemeMetrics.Padding.small) {
                Text(displayName ?? "User")
                    .font(ThemeFont.title())
                    .foregroundColor(ThemeColor.text.color)
                
                Text(email ?? "")
                    .font(ThemeFont.body())
                    .foregroundColor(ThemeColor.secondaryText.color)
            }
            
            Button(action: onEditProfile) {
                Text("Edit Profile")
                    .font(ThemeFont.headline())
            }
            .themeButton(style: .secondary)
            .frame(width: 120)
        }
        .padding(.vertical)
    }
}

struct StatsSection: View {
    let playlistCount: Int
    let totalSongs: Int
    let listeningTime: String
    
    var body: some View {
        VStack(spacing: ThemeMetrics.Padding.medium) {
            Text("Your Music Stats")
                .font(ThemeFont.headline())
                .foregroundColor(ThemeColor.text.color)
            
            HStack(spacing: ThemeMetrics.Padding.extraLarge) {
                StatItem(title: "Playlists", value: "\(playlistCount)")
                StatItem(title: "Songs", value: "\(totalSongs)")
                StatItem(title: "Listened", value: listeningTime)
            }
        }
        .padding()
        .background(ThemeColor.text.color.opacity(0.1))
        .cornerRadius(ThemeMetrics.CornerRadius.large)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: ThemeMetrics.Padding.small) {
            Text(value)
                .font(ThemeFont.title())
                .foregroundColor(ThemeColor.text.color)
            
            Text(title)
                .font(ThemeFont.caption())
                .foregroundColor(ThemeColor.secondaryText.color)
        }
    }
}

struct SettingsSection: View {
    let title: String
    let items: [SettingsItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ThemeMetrics.Padding.medium) {
            Text(title)
                .font(ThemeFont.headline())
                .foregroundColor(ThemeColor.text.color)
            
            VStack(spacing: ThemeMetrics.Padding.small) {
                ForEach(items) { item in
                    SettingsItemView(item: item)
                }
            }
        }
    }
}

struct SettingsItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    var value: String? = nil
    var hasToggle: Bool = false
    var isToggled: Binding<Bool> = .constant(false)
    var textColor: Color = ThemeColor.text.color
    var action: (() -> Void)? = nil
}

struct SettingsItemView: View {
    let item: SettingsItem
    
    var body: some View {
        Button(action: {
            if item.hasToggle {
                item.isToggled.wrappedValue.toggle()
            } else {
                item.action?()
            }
        }) {
            HStack {
                Image(systemName: item.icon)
                    .font(.system(size: ThemeMetrics.IconSize.medium))
                    .foregroundColor(item.textColor)
                    .frame(width: ThemeMetrics.IconSize.large)
                
                Text(item.title)
                    .font(ThemeFont.body())
                    .foregroundColor(item.textColor)
                
                Spacer()
                
                if item.hasToggle {
                    Toggle("", isOn: item.isToggled)
                        .labelsHidden()
                } else if let value = item.value {
                    Text(value)
                        .font(ThemeFont.body())
                        .foregroundColor(ThemeColor.secondaryText.color)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: ThemeMetrics.IconSize.small))
                        .foregroundColor(ThemeColor.secondaryText.color)
                }
            }
            .padding()
            .background(ThemeColor.text.color.opacity(0.1))
            .cornerRadius(ThemeMetrics.CornerRadius.medium)
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
}
