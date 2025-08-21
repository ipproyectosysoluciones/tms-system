# TMS Transportation Logistics System

## Presentación Ejecutiva y Técnica

---

## 📋 Agenda de la Presentación (90 minutos)

### **Bloque 1: Visión General del Negocio** (20 min)

- Introducción al TMS y Propósito del Sistema
- Beneficios de Negocio y ROI
- Casos de Uso Principales

### **Bloque 2: Roles y Funcionalidades** (15 min)

- Los 4 Roles del Sistema
- Flujos de Trabajo por Rol
- Permisos y Seguridad

### **Bloque 3: Arquitectura del Sistema** (20 min)

- Componentes Tecnológicos
- Arquitectura Limpia (Clean Architecture)
- Infraestructura con Docker

### **Bloque 4: Proceso de Instalación Automatizada** (20 min)

- Script de Setup Inteligente
- Proceso Paso a Paso
- Validaciones y Recuperación de Errores

### **Bloque 5: Monitoreo, Backup y Seguridad** (10 min)

- Sistema de Monitoreo en Tiempo Real
- Estrategia de Backup Automático
- Medidas de Seguridad Implementadas

### **Bloque 6: Q&A y Demo** (5 min)

- Preguntas y Respuestas
- Próximos Pasos

---

## 🚀 Bloque 1: Visión General del Negocio

### ¿Qué es TMS Transportation Logistics System?

**TMS** es una plataforma integral de gestión de transporte y logística diseñada para optimizar operaciones de empresas transportistas, clientes que requieren servicios de transporte, y conductores.

### 🎯 Propósito Principal

- **Centralizar** todas las operaciones de transporte en una sola plataforma
- **Optimizar** rutas, costos y tiempos de entrega
- **Facilitar** la comunicación entre todos los actores del proceso logístico
- **Automatizar** procesos manuales y reducir errores humanos
- **Proporcionar** visibilidad total del estado de envíos y vehículos

### 💰 Beneficios de Negocio

#### Para Empresas Transportistas (Carriers)

- **Reducción de costos operativos**: Hasta 20% en combustible por optimización de rutas
- **Mayor utilización de flota**: Incremento del 15% en eficiencia de vehículos
- **Mejora en satisfacción del cliente**: Entregas puntuales y comunicación proactiva

#### Para Clientes (Shippers)

- **Visibilidad completa**: Tracking en tiempo real de todos sus envíos
- **Reducción de inventarios**: Mejor planificación de entregas JIT (Just In Time)
- **Menor costo logístico**: Comparación automática de tarifas y proveedores

#### Para Conductores

- **Rutas optimizadas**: GPS integrado con planificación inteligente
- **Comunicación eficiente**: App móvil para actualizaciones en tiempo real
- **Gestión de documentos**: Digitalización de papeles y procesos

### 🏭 Casos de Uso Principales

1. **Gestión de Órdenes de Transporte**

   - Creación automática de órdenes desde sistemas ERP
   - Asignación inteligente de vehículos y conductores
   - Tracking en tiempo real del progreso

2. **Optimización de Rutas y Cargas**

   - Algoritmos de optimización para múltiples entregas
   - Consolidación de cargas para máxima eficiencia
   - Consideración de restricciones de tráfico y horarios

3. **Gestión de Flota Integral**

   - Mantenimiento preventivo programado
   - Control de combustible y costos operativos
   - Monitoreo de performance de conductores

4. **Facturación y Pagos Automatizados**
   - Generación automática de facturas
   - Integración con PayPal para pagos digitales
   - Reconciliación automática de cuentas

---

## 👥 Bloque 2: Los 4 Roles del Sistema

### 🔐 Arquitectura de Permisos Basada en Roles (RBAC)

El sistema TMS implementa un control de acceso granular donde cada usuario tiene permisos específicos según su rol en la operación logística.

### 1. 👨‍💼 **ADMIN** - Administrador del Sistema

**Responsabilidades:**

- Configuración general del sistema
- Gestión de usuarios y permisos
- Monitoreo de performance global
- Configuración de integraciones

**Permisos Principales:**

```text
✅ Acceso total al sistema
✅ Gestión de usuarios y roles
✅ Configuración de parámetros del sistema
✅ Acceso a reportes ejecutivos
✅ Configuración de integraciones
✅ Gestión de backups y seguridad
```

**Flujo de Trabajo Típico:**

1. Configura nuevas empresas transportistas
2. Define parámetros operativos (zonas, tarifas base)
3. Monitorea KPIs globales del sistema
4. Resuelve escalaciones críticas

### 2. 🚛 **CARRIER** - Empresa Transportista

**Responsabilidades:**

- Gestión de flota de vehículos
- Administración de conductores
- Fijación de tarifas y servicios
- Asignación de rutas

**Permisos Principales:**

```text
✅ Gestión completa de su flota
✅ Administración de conductores propios
✅ Configuración de tarifas y servicios
✅ Asignación de órdenes a vehículos
✅ Reportes de performance de flota
❌ Acceso a datos de otros carriers
```

**Flujo de Trabajo Típico:**

1. Recibe notificaciones de nuevas órdenes disponibles
2. Evalúa capacidad y disponibilidad de flota
3. Asigna conductor y vehículo óptimo
4. Monitorea progreso de entregas
5. Factura servicios prestados

### 3. 👤 **CLIENT** - Cliente/Shipper

**Responsabilidades:**

- Creación de órdenes de transporte
- Seguimiento de envíos
- Evaluación de proveedores
- Gestión de inventarios

**Permisos Principales:**

```text
✅ Crear órdenes de transporte
✅ Tracking de sus envíos
✅ Ver histórico de servicios
✅ Evaluar carriers y conductores
✅ Descargar documentos de entrega
❌ Acceso a información de otros clientes
```

**Flujo de Trabajo Típico:**

1. Crea orden con detalles de pickup y entrega
2. Compara ofertas de diferentes carriers
3. Selecciona mejor opción precio/tiempo
4. Monitorea progreso en tiempo real
5. Confirma entrega y califica servicio

### 4. 🚚 **DRIVER** - Conductor

**Responsabilidades:**

- Ejecución de rutas asignadas
- Actualización de estatus de entregas
- Captura de evidencias de entrega
- Comunicación con dispatcher

**Permisos Principales:**

```text
✅ Ver rutas asignadas
✅ Actualizar status de entregas
✅ Capturar fotos/firmas de entrega
✅ Comunicarse con central de operaciones
✅ Reportar incidencias
❌ Modificar asignaciones de rutas
```

**Flujo de Trabajo Típico:**

1. Recibe asignación de ruta en app móvil
2. Confirma pickup de mercancía
3. Sigue ruta optimizada por GPS
4. Actualiza estatus en cada punto
5. Captura evidencia de entrega satisfactoria

---

## 🏗️ Bloque 3: Arquitectura del Sistema

### 📐 Arquitectura Limpia (Clean Architecture)

El sistema TMS está construido siguiendo los principios de Clean Architecture, garantizando:

- **Separación de responsabilidades**
- **Independencia de frameworks**
- **Facilidad de testing**
- **Mantenibilidad a largo plazo**

### 🎯 Capas de la Arquitectura

#### **1. Core (Núcleo de Negocio)**

```text
backend/src/core/
├── entities/          # Entidades de dominio
├── repositories/      # Interfaces de repositorios
└── services/         # Servicios de dominio
```

**Responsabilidades:**

- Lógica de negocio pura (sin dependencias externas)
- Entidades del dominio (User, Order, Vehicle, Route)
- Reglas de negocio críticas

#### **2. Infrastructure (Infraestructura)**

```text
backend/src/infrastructure/
├── database/         # Configuración de base de datos
├── repositories/     # Implementaciones de repositorios
└── external/        # Servicios externos (PayPal, GPS)
```

**Responsabilidades:**

- Acceso a datos (Prisma ORM)
- Integraciones con servicios externos
- Configuraciones de infraestructura

#### **3. Application (Aplicación)**

```text
backend/src/application/
├── dtos/            # Data Transfer Objects
├── services/        # Servicios de aplicación
└── use-cases/       # Casos de uso específicos
```

**Responsabilidades:**

- Orquestación de operaciones
- Casos de uso del negocio
- Transformación de datos

#### **4. Presentation (Presentación)**

```text
backend/src/presentation/
├── controllers/     # Controladores REST API
├── middlewares/     # Middlewares personalizados
└── guards/         # Guards de autenticación/autorización
```

**Responsabilidades:**

- API REST endpoints
- Autenticación y autorización
- Validación de entrada

### 🛠️ Stack Tecnológico

#### **Backend**

- **Framework:** NestJS (Node.js 22.x)
- **Lenguaje:** TypeScript (strict mode)
- **ORM:** Prisma (type-safe database access)
- **Autenticación:** JWT + Passport
- **Documentación:** Swagger/OpenAPI

#### **Base de Datos**

- **Principal:** MySQL 8.0 (ACID compliance)
- **Cache:** Redis 7-alpine (sesiones + cache)
- **Migraciones:** Prisma Migrate (versionado de esquema)

#### **Infraestructura**

- **Contenedores:** Docker + Docker Compose
- **Proxy:** Nginx (load balancing + SSL)
- **Monitoreo:** Prometheus + Grafana
- **CI/CD:** GitHub Actions

### 🐳 Arquitectura con Docker

#### **Servicios en Contenedores**

1. **Backend Service**

   - NestJS application
   - Auto-scaling horizontal
   - Health checks integrados

2. **MySQL Service**

   - MySQL 8.0 con configuración optimizada
   - Persistent volumes para datos
   - Backups automatizados

3. **Redis Service**

   - Cache y gestión de sesiones
   - Configuración para alta disponibilidad
   - Particionado por base de datos

4. **Monitoring Stack**

   - Prometheus (métricas)
   - Grafana (dashboards)
   - Alert Manager (notificaciones)

5. **Load Balancer**
   - Nginx con SSL termination
   - Rate limiting
   - Static asset serving

#### **Ventajas de la Containerización**

- **Consistencia:** Mismo ambiente en desarrollo, testing y producción
- **Escalabilidad:** Fácil scaling horizontal de servicios
- **Aislamiento:** Cada servicio en su propio contenedor
- **Portabilidad:** Funciona en cualquier plataforma con Docker
- **Eficiencia:** Uso optimizado de recursos del servidor

---

## ⚙️ Bloque 4: Proceso de Instalación Automatizada

### ✅ **Opción Recomendada: WSL (Windows Subsystem for Linux)**

**Ventajas:**

- Compatibilidad 100% con el script original
- Entorno Linux completo dentro de Windows
- Mejor rendimiento para desarrollo
- Acceso completo a herramientas Unix/Linux

**Pasos detallados:**

1. **Habilitar WSL:**

   ```powershell
   # En PowerShell como Administrador
   wsl --install
   # Reiniciar el sistema
   ```

2. **Instalar Ubuntu:**

   ```powershell
   wsl --install -d Ubuntu-24.04
   ```

3. **Configurar entorno en Ubuntu:**

   ```bash
   # Actualizar sistema
   sudo apt update && sudo apt upgrade -y

   # Instalar Node.js 22.x
   # Descarga e instala nvm:
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

   # en lugar de reiniciar la shell
   \. "$HOME/.nvm/nvm.sh"

   # Descarga e instala Node.js:
   nvm install 22

   # Verifica la versión de Node.js:
   node -v # Debería mostrar "v22.18.0".
   nvm current # Debería mostrar "v22.18.0".

   # Descarga e instala pnpm:
   corepack enable pnpm

   # Verifica versión de pnpm:
   pnpm -v

   # Instalar pnpm
   sudo npm install -g pnpm

   # Instalar Docker
   sudo apt-get install -y docker.io docker-compose-plugin
   sudo usermod -aG docker $USER

   # Reiniciar sesión WSL
   exit
   wsl
   ```

4. **Ejecutar el script original:**

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

---

### 🎯 Filosofía del Script de Setup

El script `install.sh` está diseñado como un **asistente inteligente** que:

- **Valida prerrequisitos** antes de comenzar
- **Maneja errores gracefully** con recuperación automática
- **Crea backups** antes de modificar archivos existentes
- **Registra todo** en logs detallados para debugging
- **Ofrece rollback** en caso de fallos

### 📋 Proceso Paso a Paso

#### **Fase 1: Validación de Prerrequisitos** ⏱️ (2-3 minutos)

```bash
# El script verifica automáticamente:
✅ Node.js 22.x instalado
✅ pnpm package manager disponible
✅ Docker y Docker Compose funcionando
✅ Git configurado correctamente
✅ Puertos necesarios (3000, 3306, 6379) disponibles
✅ Permisos de escritura en directorio
```

**¿Qué pasa si falta algo?**

- El script **se detiene** y explica qué instalar
- Proporciona **comandos exactos** para resolver el problema
- **No continúa** hasta que todo esté correcto

#### **Fase 2: Creación de Estructura de Directorios** ⏱️ (1 minuto)

```text
tms-project/
├── backend/                 # Aplicación NestJS
│   ├── src/
│   │   ├── core/           # Lógica de negocio
│   │   ├── infrastructure/ # Acceso a datos
│   │   ├── application/    # Casos de uso
│   │   └── presentation/   # API controllers
│   ├── prisma/             # Database schema
│   └── test/               # Tests organizados
├── scripts/                # Scripts de automatización
├── mysql/                  # Configuración MySQL
├── redis/                  # Configuración Redis
├── monitoring/             # Prometheus/Grafana
└── docs/                   # Documentación completa
```

#### **Fase 3: Configuración de Base de Datos** ⏱️ (2 minutos)

**MySQL 8.0 Setup:**

```sql
-- Crear múltiples bases de datos
CREATE DATABASE tms_db;           -- Producción
CREATE DATABASE tms_test_db;      -- Testing

-- Usuarios con permisos granulares
CREATE USER 'tms_admin'@'%';      -- Admin completo
CREATE USER 'tms_user'@'%';       -- Aplicación
CREATE USER 'tms_carrier'@'%';    -- Solo datos de carrier
CREATE USER 'tms_client'@'%';     -- Solo datos de cliente
CREATE USER 'tms_driver'@'%';     -- Solo rutas asignadas
```

**¿Por qué múltiples usuarios?**

- **Seguridad por capas:** Cada rol solo accede a sus datos
- **Auditoría:** Trazabilidad de quién modifica qué
- **Compliance:** Cumplimiento de normativas de datos
- **Performance:** Queries optimizadas por tipo de usuario

#### **Fase 4: Configuración de Redis** ⏱️ (1 minuto)

```text
Database 0: Sesiones de usuario
Database 1: Cache de aplicación
Database 2: Colas de trabajo (Bull queues)
```

**Configuraciones de Seguridad:**

- Password required
- Comandos peligrosos deshabilitados
- Rate limiting configurado

#### **Fase 5: Setup de NestJS Application** ⏱️ (5-8 minutos)

```typescript
// El script genera automáticamente:
1. package.json con todas las dependencias
2. tsconfig.json optimizado para Node.js 22
3. Estructura de módulos de NestJS
4. Configuración de Prisma ORM
5. Guards de autenticación JWT
6. Swagger/OpenAPI documentation
7. Health check endpoints
8. Error handling global
```

#### **Fase 6: Docker Configuration** ⏱️ (2 minutos)

**Tres ambientes configurados:**

1. **Development** (`docker-compose.yml`)

   - Hot reload habilitado
   - Logs verbosos
   - Debugger ports expuestos

2. **Production** (`docker-compose.prod.yml`)

   - Multi-stage builds optimizados
   - Resource limits configurados
   - SSL/TLS habilitado

3. **Testing** (`docker-compose.test.yml`)
   - Bases de datos aisladas
   - Configuración para CI/CD

#### **Fase 7: Scripts de Automatización** ⏱️ (1 minuto)

```bash
scripts/
├── deploy.sh    # Deployment a producción/staging
├── backup.sh    # Backup automático con rotación
├── test.sh      # Test runner completo
└── setup.sh     # Este mismo script (auto-replication)
```

#### **Fase 8: Configuración de Monitoreo** ⏱️ (2 minutos)

- **Prometheus:** Configurado para scraping de métricas
- **Grafana:** Dashboards pre-configurados
- **Health Checks:** Endpoints para monitoring
- **Alerting:** Reglas de alertas críticas

#### **Fase 9: GitHub Actions CI/CD** ⏱️ (1 minuto)

```yaml
Workflows generados:
1. ci.yml          # Tests en cada PR
2. deploy.yml      # Deploy automático a prod
3. security.yml    # Security scanning
```

### 🛡️ Manejo de Errores y Recuperación

#### **Sistema de Logging Avanzado**

```bash
# Cada acción se registra con timestamp y contexto
[2024-01-15 10:30:25][INFO] Starting TMS setup process
[2024-01-15 10:30:26][DEBUG] Checking Node.js version: 22.1.0 ✅
[2024-01-15 10:30:27][ERROR] Docker not running ❌
[2024-01-15 10:30:28][INFO] Attempting Docker startup...
```

#### **Backup Automático**

- **Antes de modificar:** Crea backup de archivos existentes
- **Rotación inteligente:** Mantiene últimos 7 backups
- **Rollback fácil:** Un comando restaura estado anterior

#### **Validación Continua**

- Cada paso valida que el anterior fue exitoso
- Tests de conectividad después de cada servicio
- Verificación de integridad de archivos generados

### 🎯 Comandos Post-Instalación

Una vez completada la instalación:

```bash
# Levantar el ambiente completo
docker-compose up -d

# Ejecutar migraciones de base de datos
cd backend && npx prisma migrate dev

# Poblar con datos de prueba
npx prisma db seed

# Iniciar desarrollo
pnpm start:dev

# Ejecutar tests completos
./scripts/test.sh all
```

---

## 🔍 Bloque 5: Monitoreo, Backup y Seguridad

### 📊 Sistema de Monitoreo en Tiempo Real

#### **Stack de Monitoreo**

### Prometheus + Grafana + AlertManager

1. **Prometheus** (Recolección de Métricas)

   ```yaml
   Métricas Capturadas:
     - API Response Times
     - Database Connection Pool
     - Redis Hit/Miss Ratios
     - Memory & CPU Usage
     - Active User Sessions
     - Order Processing Rates
     - Vehicle GPS Updates
   ```

2. **Grafana** (Visualización)

   ```yaml
   Dashboards Pre-configurados:
     - TMS Business KPIs
     - System Performance
     - User Activity Heatmaps
     - Fleet Utilization
     - API Health Status
     - Database Performance
   ```

3. **Alerting** (Notificaciones Proactivas)

   ```yaml
   Alertas Críticas:
     - Sistema down > 30 segundos
     - Database connections > 90%
     - API response time > 5 segundos
     - Disk space < 10%
     - Failed logins > 10 en 5 minutos
   ```

#### **Health Checks Inteligentes**

```http
GET /health/
Response: {
  "status": "OK",
  "timestamp": "2024-01-15T10:30:00Z",
  "services": {
    "database": "healthy",
    "redis": "healthy",
    "external_apis": "healthy"
  },
  "metrics": {
    "uptime": "72h 15m",
    "active_users": 245,
    "pending_orders": 12
  }
}
```

### 💾 Estrategia de Backup Automático

#### **Backup Multinivel**

1. **Database Backups**

   ```bash
   # Backup completo diario
   mysqldump --single-transaction --routines --triggers tms_db

   # Backup incremental cada 6 horas
   mysqlbinlog --start-datetime="6 hours ago"
   ```

2. **Application Backups**

   ```bash
   # Código y configuraciones
   tar -czf app_backup_$(date +%Y%m%d).tar.gz \
       --exclude=node_modules \
       --exclude=logs backend/ scripts/ docker-compose.yml
   ```

3. **Redis Persistence**

   ```bash
   # RDB snapshots automáticos
   save 900 1     # Al menos 1 cambio en 15 minutos
   save 300 10    # Al menos 10 cambios en 5 minutos
   save 60 10000  # Al menos 10000 cambios en 1 minuto
   ```

#### **Rotación y Retención**

```bash
Política de Retención:
- Backups diarios: 30 días
- Backups semanales: 12 semanas
- Backups mensuales: 12 meses
- Backups anuales: 7 años
```

#### **Verificación de Integridad**

- **Checksum validation:** MD5 de cada backup
- **Restore testing:** Test automático de restauración
- **Corruption detection:** Validación de estructura de datos

### 🔒 Medidas de Seguridad Implementadas

#### **Autenticación y Autorización**

1. **JWT Tokens Seguros**

   ```typescript
   {
     "access_token": "15 minutos de vida",
     "refresh_token": "7 días de vida",
     "algorithm": "RS256 (asymmetric)",
     "issuer": "TMS-System",
     "audience": "TMS-Users"
   }
   ```

2. **Role-Based Access Control (RBAC)**

   ```typescript
   @UseGuards(JwtAuthGuard, RolesGuard)
   @Roles('admin', 'carrier')
   @ApiSecurity('bearer')
   async getFleetData() {
     // Solo admin y carrier pueden acceder
   }
   ```

#### **Protección de Datos**

1. **Encriptación**

   ```yaml
   En Tránsito:
     - HTTPS/TLS 1.3 obligatorio
     - Certificate pinning en mobile apps

   En Reposo:
     - Database encryption at rest
     - Encrypted backups (AES-256)
     - Password hashing (bcrypt, salt rounds: 12)
   ```

2. **Validación de Entrada**

   ```typescript
   @IsEmail()
   @IsNotEmpty()
   @MaxLength(255)
   @Transform(({ value }) => value.toLowerCase().trim())
   email: string;
   ```

#### **Seguridad de Red**

1. **Rate Limiting**

   ```typescript
   @Throttle(10, 60) // 10 requests per minute
   async login() {
     // Previene ataques de fuerza bruta
   }
   ```

2. **Security Headers**

   ```typescript
   app.use(
     helmet({
       contentSecurityPolicy: true,
       crossOriginEmbedderPolicy: true,
       hsts: { maxAge: 31536000 },
     }),
   );
   ```

#### **Auditoría y Compliance**

1. **Logging Comprehensivo**

   ```typescript
   // Cada acción crítica se registra
   {
     "timestamp": "2024-01-15T10:30:00Z",
     "user_id": "user123",
     "action": "order_created",
     "resource": "order_456",
     "ip_address": "192.168.1.100",
     "user_agent": "TMS-Mobile/1.0"
   }
   ```

2. **GDPR Compliance**

   ```typescript
   // Right to be forgotten
   @Delete('/users/:id/data')
   async deleteUserData(@Param('id') userId: string) {
     // Eliminación completa de datos personales
     await this.userService.anonymizeUserData(userId);
   }
   ```

#### **Monitoreo de Seguridad**

```yaml
Eventos Monitoreados:
  - Multiple failed login attempts
  - Privilege escalation attempts
  - SQL injection attempts
  - Unusual API usage patterns
  - Geo-location anomalies
  - After-hours admin access
```

### 🚨 Incident Response

#### **Procedimientos Automatizados**

1. **Detection** (< 1 minuto)

   - Alertas automáticas por Prometheus
   - Log analysis con patrones anómalos

2. **Response** (< 5 minutos)

   - Aislamiento automático de servicios comprometidos
   - Activación de modo de solo lectura
   - Notificación al equipo de seguridad

3. **Recovery** (< 30 minutos)
   - Rollback automático a último backup confiable
   - Verificación de integridad del sistema
   - Restauración gradual de servicios

---

## 🎯 Conclusiones y Q&A

### 📈 Resumen Ejecutivo

**TMS Transportation Logistics System** representa una solución moderna y escalable que:

✅ **Moderniza** procesos logísticos tradicionales
✅ **Reduce costos** operativos significativamente  
✅ **Mejora** la experiencia de todos los stakeholders
✅ **Garantiza** seguridad y compliance empresarial
✅ **Escala** con el crecimiento del negocio

### 🔧 Para el Equipo de Desarrollo

**Beneficios Técnicos:**

- Setup automático en **< 20 minutos**
- Arquitectura probada y escalable
- Testing comprehensivo incluido
- CI/CD configurado desde día uno
- Documentación completa y actualizada

### 💼 Para Ejecutivos e Inversionistas

**ROI Esperado:**

- **Reducción de costos operativos:** 15-25%
- **Mejora en satisfacción del cliente:** 30%+
- **Reducción de tiempo de deployment:** 90%
- **Disminución de errores humanos:** 80%
- **Tiempo de time-to-market:** Aceleración de 6 meses

### 🚀 Próximos Pasos

1. **Aprobación del proyecto** y asignación de recursos
2. **Setup del ambiente de desarrollo** (1 día)
3. **Configuración de ambientes** de staging y producción
4. **Inicio del desarrollo iterativo** por módulos
5. **Testing y validación** con usuarios piloto

---

## ❓ Preguntas y Respuestas

**¿Listos para transformar su operación logística?**

---

### 📞 Contacto del Proyecto

- **Equipo de Desarrollo:** <developers@tms-project.com>
- **Soporte Técnico:** <support@tms-project.com>
- **Documentación:** [GitHub Repository](https://github.com/company/tms-project)

---

### Audiencia Objetivo

Presentación preparada para audiencia mixta: Ejecutivos, Gerentes de Proyecto, Inversionistas y Desarrolladores
