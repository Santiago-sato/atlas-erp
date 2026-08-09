package com.atlaserp.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "permisos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Permiso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String codigo;

    @Column(nullable = false, length = 50)
    private String modulo;

    @Column(nullable = false, length = 50)
    private String accion;

    @Column(length = 255)
    private String descripcion;

    @ManyToMany(mappedBy = "permisos")
    @Builder.Default
    private Set<Rol> roles = new HashSet<>();
}
