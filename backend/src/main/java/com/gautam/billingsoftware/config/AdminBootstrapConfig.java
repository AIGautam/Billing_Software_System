package com.gautam.billingsoftware.config;

import com.gautam.billingsoftware.entity.UserEntity;
import com.gautam.billingsoftware.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.UUID;

@Slf4j
@Configuration
@RequiredArgsConstructor
public class AdminBootstrapConfig {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.bootstrap.admin.enabled:true}")
    private boolean bootstrapAdminEnabled;

    @Value("${app.bootstrap.admin.email:admin@gmail.com}")
    private String bootstrapAdminEmail;

    @Value("${app.bootstrap.admin.password:123456}")
    private String bootstrapAdminPassword;

    @Value("${app.bootstrap.admin.name:Admin}")
    private String bootstrapAdminName;

    @Value("${app.bootstrap.admin.role:ROLE_ADMIN}")
    private String bootstrapAdminRole;

    @Bean
    CommandLineRunner bootstrapAdminUser() {
        return args -> {
            if (!bootstrapAdminEnabled || userRepository.count() > 0) {
                return;
            }

            UserEntity adminUser = UserEntity.builder()
                    .userId(UUID.randomUUID().toString())
                    .email(bootstrapAdminEmail)
                    .password(passwordEncoder.encode(bootstrapAdminPassword))
                    .role(bootstrapAdminRole)
                    .name(bootstrapAdminName)
                    .build();

            userRepository.save(adminUser);
            log.info("Bootstrapped default admin user with email {}", bootstrapAdminEmail);
        };
    }
}
