-- ============================================
-- BOOKING INTERNO - Schema PostgreSQL
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ENUM types
CREATE TYPE user_role AS ENUM ('employee', 'admin');
CREATE TYPE resource_type AS ENUM ('meeting_room', 'desk', 'equipment');
CREATE TYPE booking_status AS ENUM ('confirmed', 'cancelled', 'pending');

-- ============================================
-- USERS
-- ============================================
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,
    role        user_role NOT NULL DEFAULT 'employee',
    department  VARCHAR(100),
    avatar_color VARCHAR(7) DEFAULT '#4F46E5',
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- RESOURCES
-- ============================================
CREATE TABLE resources (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name         VARCHAR(150) NOT NULL,
    type         resource_type NOT NULL,
    description  TEXT,
    capacity     INT,                          -- per sale riunioni
    location     VARCHAR(100),                 -- es. "Piano 2 - Ala Nord"
    amenities    JSONB DEFAULT '[]',           -- es. ["Projector","Whiteboard"]
    is_active    BOOLEAN DEFAULT TRUE,
    image_url    VARCHAR(255),
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- BOOKINGS
-- ============================================
CREATE TABLE bookings (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    resource_id  UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    title        VARCHAR(200) NOT NULL,
    notes        TEXT,
    start_time   TIMESTAMPTZ NOT NULL,
    end_time     TIMESTAMPTZ NOT NULL,
    status       booking_status NOT NULL DEFAULT 'confirmed',
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    updated_at   TIMESTAMPTZ DEFAULT NOW(),

    -- Prevent overlapping bookings for the same resource
    CONSTRAINT no_overlap EXCLUDE USING gist (
        resource_id WITH =,
        tstzrange(start_time, end_time, '[)') WITH &&
    ) WHERE (status = 'confirmed')
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_bookings_resource_time ON bookings(resource_id, start_time, end_time);
CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_date ON bookings(start_time);
CREATE INDEX idx_resources_type ON resources(type);

-- ============================================
-- SEED DATA
-- ============================================
INSERT INTO users (name, email, password, role, department, avatar_color) VALUES
('Admin Sistema', 'admin@company.com', '$2b$10$rQZ9uAVMXtCkfYMlj3Rj0.example_hash', 'admin', 'IT', '#7C3AED'),
('Marco Rossi', 'marco.rossi@company.com', '$2b$10$rQZ9uAVMXtCkfYMlj3Rj0.example_hash', 'employee', 'Sviluppo', '#059669'),
('Laura Bianchi', 'laura.bianchi@company.com', '$2b$10$rQZ9uAVMXtCkfYMlj3Rj0.example_hash', 'employee', 'Marketing', '#DC2626'),
('Giovanni Verdi', 'giovanni.verdi@company.com', '$2b$10$rQZ9uAVMXtCkfYMlj3Rj0.example_hash', 'employee', 'Commerciale', '#D97706');

INSERT INTO resources (name, type, description, capacity, location, amenities) VALUES
('Sala Alfa', 'meeting_room', 'Sala riunioni principale con vista esterna', 10, 'Piano 1', '["Proiettore","Lavagna","Videoconferenza","Clima"]'),
('Sala Beta', 'meeting_room', 'Sala piccola per call e meeting rapidi', 4, 'Piano 1', '["TV 55"","Webcam","Lavagna magnetica"]'),
('Sala Gamma', 'meeting_room', 'Sala executive per presentazioni clienti', 16, 'Piano 2', '["Proiettore 4K","Sistema audio","Clima","Catering disponibile"]'),
('Desk A1', 'desk', 'Postazione open space zona A', 1, 'Piano 1 - Open Space A', '["Monitor 27"","Dock USB-C","Locker"]'),
('Desk A2', 'desk', 'Postazione open space zona A', 1, 'Piano 1 - Open Space A', '["Monitor 27"","Dock USB-C","Locker"]'),
('Desk B1', 'desk', 'Postazione open space zona B - vicino finestre', 1, 'Piano 1 - Open Space B', '["Monitor 34" Ultrawide","Dock","Vista esterna"]'),
('Proiettore Portatile', 'equipment', 'Proiettore Full HD con borsa trasporto', NULL, 'Armadio Attrezzature', '["HDMI","VGA","USB","Telecomando"]'),
('MacBook Pro 16"', 'equipment', 'Laptop per presentazioni esterne o smart working', NULL, 'Armadio Attrezzature', '["M3 Pro","32GB RAM","Caricatore incluso"]'),
('Kit Videoconferenza', 'equipment', 'Webcam 4K + microfono omnidirezionale + speaker', NULL, 'Armadio Attrezzature', '["USB-C","Compatibile Zoom/Teams","Custodia"]');
