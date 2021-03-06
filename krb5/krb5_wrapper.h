#pragma once

#include <string>
#include <vector>
#include <stdint.h>

typedef int32_t krb5_timestamp;
typedef int32_t krb5_error_code;

struct _krb5_context;
typedef struct _krb5_context * krb5_context;

struct krb5_principal_data;
typedef krb5_principal_data * krb5_principal;

struct krb5_keytab_entry_st;
typedef struct krb5_keytab_entry_st krb5_keytab_entry;

struct _krb5_kt;
typedef struct _krb5_kt *krb5_keytab;


namespace arsoft {
    namespace krb5 {

class context
{
private:
    krb5_context _ctx;
public:
    context();
    ~context();

    operator krb5_context() const
        { return _ctx; }
};

class base_object
{
protected:
    const context & _ctx;
    base_object(const context & ctx);
    base_object(const base_object & rhs);
public:
    virtual ~base_object();
    const context & get_context() const;
};

class error : public std::exception
{
public:
    error(base_object * obj, int error_code);
    error(base_object * obj, const std::string & msg, int error_code);
    ~error() throw ();

    virtual const char* what() const throw();

    base_object * object() const { return _obj; }
    const std::string & message() const { return _msg; }
    int code() const { return _error_code; }

protected:
    base_object * _obj;
    std::string _msg;
    int _error_code;
};

class principal : public base_object
{
protected:
    krb5_principal _handle;
    std::string _name;
public:
    principal(const context & ctx, const krb5_principal & h);

    bool operator==(const principal & rhs) const;
    bool operator!=(const principal & rhs) const;
    bool operator<(const principal & rhs) const;

    const std::string & name() const;
    operator std::string() const { return name(); }
};

class timestamp
{
protected:
    krb5_timestamp _ts;
public:
    timestamp(krb5_timestamp timestamp=0);

    std::string to_string() const;

    bool operator<(const timestamp & rhs) const
    {
        return _ts < rhs._ts;
    }
    bool operator==(const timestamp & rhs) const
    {
        return _ts == rhs._ts;
    }
    bool operator!=(const timestamp & rhs) const
    {
        return _ts == rhs._ts;
    }
};

class keytab_entry : public base_object
{
    krb5_keytab_entry * _entry;
    bool _allocated;
public:
    keytab_entry(const context & ctx, krb5_keytab_entry * entry);
    keytab_entry(const keytab_entry & rhs);
    ~keytab_entry();

    int get_magic() const;
    int get_key_version() const;
    principal get_principal() const;
    timestamp get_timestamp() const;
    int get_encryption() const;
    std::string get_encryption_as_string(bool shortest=false) const;
};

class keytab : public base_object
{
    krb5_keytab _handle;
    std::string _filename;
    bool _ok;
public:
    keytab(const context & ctx, const std::string & filename);
    ~keytab();
    bool valid() const;
    const std::string & get_filename() const;

    struct list_handler {
        virtual void operator()(const keytab_entry & entry) = 0;
    };
    bool list(list_handler & handler);

    template<typename LIST_HANDLER>
    bool list(LIST_HANDLER & handler)
    {
        struct list_handler_impl : public list_handler {
            LIST_HANDLER & _handler;
            list_handler_impl(LIST_HANDLER & handler) : _handler(handler) {}
            virtual void operator()(const keytab_entry & entry)
            {
                _handler(entry);
            }
        };
        list_handler_impl impl(handler);
        return list(static_cast<list_handler & >(impl));
    }
    bool update(const keytab & source);
    bool copy(const keytab & source);
    bool expunge();
    bool remove(const std::string & principal);

protected:
    krb5_error_code updateEntry(krb5_keytab_entry * updatedEntry);
    bool removeEntries(const std::vector<krb5_keytab_entry> & entries_to_remove);
};

    } // namespace krb5
} // namespace arsoft
