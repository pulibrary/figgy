SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: get_ids(jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_ids(jsonb, text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $_$
      select jsonb_agg(x) from
         (select jsonb_array_elements($1->$2)->>'id') as f(x);
      $_$;


--
-- Name: get_ids_array(jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_ids_array(jsonb, text) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
      select array_agg(x) from
         (select jsonb_array_elements($1->$2)->>'id') as f(x);
      $_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    service_name character varying NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: auth_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_tokens (
    id bigint NOT NULL,
    label character varying,
    "group" character varying,
    token character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    resource_id character varying
);


--
-- Name: auth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_tokens_id_seq OWNED BY public.auth_tokens.id;


--
-- Name: bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookmarks (
    id integer NOT NULL,
    user_id integer NOT NULL,
    user_type character varying,
    document_id character varying,
    document_type character varying,
    title bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bookmarks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bookmarks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookmarks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bookmarks_id_seq OWNED BY public.bookmarks.id;


--
-- Name: nomisma_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nomisma_documents (
    id bigint NOT NULL,
    state character varying,
    rdf text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: nomisma_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nomisma_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nomisma_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nomisma_documents_id_seq OWNED BY public.nomisma_documents.id;


--
-- Name: ocr_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ocr_requests (
    id bigint NOT NULL,
    filename character varying,
    state character varying,
    note text,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ocr_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ocr_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ocr_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ocr_requests_id_seq OWNED BY public.ocr_requests.id;


--
-- Name: orm_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orm_resources (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    internal_resource character varying,
    lock_version integer
);


--
-- Name: preservation_audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preservation_audits (
    id bigint NOT NULL,
    status character varying,
    extent character varying,
    batch_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: preservation_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.preservation_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preservation_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.preservation_audits_id_seq OWNED BY public.preservation_audits.id;


--
-- Name: preservation_check_failures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preservation_check_failures (
    id bigint NOT NULL,
    preservation_audit_id bigint,
    resource_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: preservation_check_failures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.preservation_check_failures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preservation_check_failures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.preservation_check_failures_id_seq OWNED BY public.preservation_check_failures.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: roles_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles_users (
    role_id integer,
    user_id integer
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: searches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.searches (
    id integer NOT NULL,
    query_params bytea,
    user_id integer,
    user_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: searches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.searches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: searches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.searches_id_seq OWNED BY public.searches.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    guest boolean DEFAULT false,
    provider character varying,
    uid character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: auth_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens ALTER COLUMN id SET DEFAULT nextval('public.auth_tokens_id_seq'::regclass);


--
-- Name: bookmarks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks ALTER COLUMN id SET DEFAULT nextval('public.bookmarks_id_seq'::regclass);


--
-- Name: nomisma_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nomisma_documents ALTER COLUMN id SET DEFAULT nextval('public.nomisma_documents_id_seq'::regclass);


--
-- Name: ocr_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_requests ALTER COLUMN id SET DEFAULT nextval('public.ocr_requests_id_seq'::regclass);


--
-- Name: preservation_audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preservation_audits ALTER COLUMN id SET DEFAULT nextval('public.preservation_audits_id_seq'::regclass);


--
-- Name: preservation_check_failures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preservation_check_failures ALTER COLUMN id SET DEFAULT nextval('public.preservation_check_failures_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: searches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.searches ALTER COLUMN id SET DEFAULT nextval('public.searches_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: auth_tokens auth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens
    ADD CONSTRAINT auth_tokens_pkey PRIMARY KEY (id);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (id);


--
-- Name: nomisma_documents nomisma_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nomisma_documents
    ADD CONSTRAINT nomisma_documents_pkey PRIMARY KEY (id);


--
-- Name: ocr_requests ocr_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_requests
    ADD CONSTRAINT ocr_requests_pkey PRIMARY KEY (id);


--
-- Name: orm_resources orm_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orm_resources
    ADD CONSTRAINT orm_resources_pkey PRIMARY KEY (id);


--
-- Name: preservation_audits preservation_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preservation_audits
    ADD CONSTRAINT preservation_audits_pkey PRIMARY KEY (id);


--
-- Name: preservation_check_failures preservation_check_failures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preservation_check_failures
    ADD CONSTRAINT preservation_check_failures_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: searches searches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.searches
    ADD CONSTRAINT searches_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: flat_member_ids_array_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flat_member_ids_array_idx ON public.orm_resources USING gin (public.get_ids_array(metadata, 'member_ids'::text));


--
-- Name: flat_member_ids_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flat_member_ids_idx ON public.orm_resources USING gin (public.get_ids(metadata, 'member_ids'::text));


--
-- Name: flat_proxied_file_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flat_proxied_file_id_idx ON public.orm_resources USING gin (public.get_ids_array(metadata, 'proxied_file_id'::text));


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_bookmarks_on_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookmarks_on_document_id ON public.bookmarks USING btree (document_id);


--
-- Name: index_bookmarks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookmarks_on_user_id ON public.bookmarks USING btree (user_id);


--
-- Name: index_ocr_requests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_requests_on_user_id ON public.ocr_requests USING btree (user_id);


--
-- Name: index_orm_resources_on_current_event; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orm_resources_on_current_event ON public.orm_resources USING btree (((metadata ->> 'resource_id'::text)), ((metadata ->> 'child_id'::text))) WHERE (((internal_resource)::text = 'Event'::text) AND (metadata @> '{"current": [true]}'::jsonb));


--
-- Name: index_orm_resources_on_current_metadata_event; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orm_resources_on_current_metadata_event ON public.orm_resources USING btree (((metadata ->> 'resource_id'::text)), ((metadata ->> 'type'::text))) WHERE (((internal_resource)::text = 'Event'::text) AND (metadata @> '{"type": ["metadata_node"], "current": [true]}'::jsonb));


--
-- Name: index_orm_resources_on_id_varchar; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orm_resources_on_id_varchar ON public.orm_resources USING btree (((id)::character varying));


--
-- Name: index_orm_resources_on_internal_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orm_resources_on_internal_resource ON public.orm_resources USING btree (internal_resource);


--
-- Name: index_orm_resources_on_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orm_resources_on_metadata ON public.orm_resources USING gin (metadata);


--
-- Name: index_orm_resources_on_metadata_jsonb_path_ops; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orm_resources_on_metadata_jsonb_path_ops ON public.orm_resources USING gin (metadata jsonb_path_ops);


--
-- Name: index_orm_resources_on_metadata_preserved_object_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orm_resources_on_metadata_preserved_object_id ON public.orm_resources USING btree (((metadata ->> 'preserved_object_id'::text))) WHERE ((internal_resource)::text = 'PreservationObject'::text);


--
-- Name: index_orm_resources_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orm_resources_on_updated_at ON public.orm_resources USING btree (updated_at);


--
-- Name: index_preservation_check_failures_on_preservation_audit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preservation_check_failures_on_preservation_audit_id ON public.preservation_check_failures USING btree (preservation_audit_id);


--
-- Name: index_roles_users_on_role_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_users_on_role_id_and_user_id ON public.roles_users USING btree (role_id, user_id);


--
-- Name: index_roles_users_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_users_on_user_id_and_role_id ON public.roles_users USING btree (user_id, role_id);


--
-- Name: index_searches_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_searches_on_user_id ON public.searches USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_provider ON public.users USING btree (provider);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_uid ON public.users USING btree (uid);


--
-- Name: mms_id_substring_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mms_id_substring_idx ON public.orm_resources USING btree ("substring"(((metadata -> 'source_metadata_identifier'::text) ->> 0), 1, 2)) WHERE ((internal_resource)::text <> ALL ((ARRAY['FileSet'::character varying, 'PreservationObject'::character varying, 'DeletionMarker'::character varying, 'Event'::character varying, 'EphemeraTerm'::character varying])::text[]));


--
-- Name: orm_resources_first_accession_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orm_resources_first_accession_number_idx ON public.orm_resources USING btree ((((metadata -> 'accession_number'::text) -> 0)));


--
-- Name: orm_resources_first_coin_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orm_resources_first_coin_number_idx ON public.orm_resources USING btree ((((metadata -> 'coin_number'::text) -> 0)));


--
-- Name: orm_resources_first_find_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orm_resources_first_find_number_idx ON public.orm_resources USING btree ((((metadata -> 'find_number'::text) -> 0)));


--
-- Name: orm_resources_first_issue_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orm_resources_first_issue_number_idx ON public.orm_resources USING btree ((((metadata -> 'issue_number'::text) -> 0)));


--
-- Name: preserved_object_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX preserved_object_id_idx ON public.orm_resources USING btree ((((((metadata -> 'preserved_object_id'::text) -> 0) ->> 'id'::text))::uuid));


--
-- Name: resource_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX resource_id_idx ON public.orm_resources USING btree ((((((metadata -> 'resource_id'::text) -> 0) ->> 'id'::text))::uuid));


--
-- Name: ocr_requests fk_rails_712a4527c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_requests
    ADD CONSTRAINT fk_rails_712a4527c4 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20251208215153'),
('20251204175843'),
('20251117211722'),
('20251007184231'),
('20250123183528'),
('20230802152303'),
('20230119155402'),
('20221214184110'),
('20220727213333'),
('20220727213332'),
('20211025213822'),
('20200608160046'),
('20200423183539'),
('20200422192849'),
('20200225213135'),
('20200225213134'),
('20200225213133'),
('20200225213132'),
('20200106182149'),
('20190102173711'),
('20181115195544'),
('20181030210350'),
('20180810215750'),
('20180306193020'),
('20180212161728'),
('20171204142457'),
('20171107160259'),
('20171025174720'),
('20170831233259'),
('20170807201421'),
('20170731174240'),
('20170724192309'),
('20170724191955'),
('20170724191229'),
('20170724191228'),
('20170724191227'),
('20170724191226'),
('20170724185403'),
('20170724185402'),
('20170724185401'),
('20170724182739');

