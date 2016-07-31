#include "krb5_wrapper.h"
#include <krb5.h>

namespace arsoft {
    namespace krb5 {


context::context()
    : _ctx(NULL)
{
    krb5_error_code code;
    code = krb5_init_context(&_ctx);
    if(code != 0)
        throw error(NULL, code);
}

context::~context()
{
    krb5_free_context(_ctx);
}

base_object::base_object(const context & ctx)
    : _ctx(ctx)
{
}

base_object::~base_object()
{
}

const context & base_object::get_context() const
{
    return _ctx;
}


error::error(base_object * obj, int error_code)
    : std::exception(), _obj(obj), _msg(), _error_code(error_code)
{
    const char * msg = krb5_get_error_message(obj->get_context(), _error_code);
    if(msg)
    {
        _msg = msg;
        krb5_free_error_message(obj->get_context(), msg);
    }
}

error::error(base_object * obj, const std::string & msg, int error_code)
    : std::exception(), _obj(obj), _msg(msg), _error_code(error_code)
{
    if(msg.empty())
    {
        const char * msg = krb5_get_error_message(obj->get_context(), _error_code);
        if(msg)
        {
            _msg = msg;
            krb5_free_error_message(obj->get_context(), msg);
        }
    }
}

error::~error() throw ()
{
}


const char* error::what() const throw()
{
    return _msg.c_str();
}


principal::principal(const context & ctx, const krb5_principal & h)
    : base_object(ctx), _handle(h)
{
}

bool principal::operator==(const principal & rhs) const
{
    return (krb5_principal_compare(_ctx, _handle, rhs._handle) != 0);
}

const std::string & principal::name() const
{
    if(_name.empty())
    {
        char * output_name = NULL;
        if(krb5_unparse_name(_ctx, _handle, &output_name) == 0)
        {
            const_cast<principal*>(this)->_name = output_name;
            krb5_free_unparsed_name(_ctx, output_name);
        }
    }
    return _name;
}

timestamp::timestamp(krb5_timestamp timestamp)
    : _ts(timestamp)
{

}
std::string timestamp::to_string() const
{
    char buf[32];
    if(krb5_timestamp_to_string(_ts, buf, sizeof(buf)) == 0)
        return buf;
    return std::string();
}

keytab_entry::keytab_entry(const context & ctx, krb5_keytab_entry * entry)
    : base_object(ctx), _entry(entry)
{
}

principal keytab_entry::get_principal() const
{
    return principal(_ctx, _entry->principal);
}

int keytab_entry::get_key_version() const
{
    return _entry->vno;
}
timestamp keytab_entry::get_timestamp() const
{
    return _entry->timestamp;
}

int keytab_entry::get_encryption() const
{
    return _entry->key.enctype;
}

std::string keytab_entry::get_encryption_as_string(bool shortest) const
{
    char buf[64];
    krb5_error_code code = krb5_enctype_to_name(_entry->key.enctype, shortest, buf, sizeof(buf));
    return buf;
}


keytab::keytab(const context & ctx, const std::string & filename)
        : base_object(ctx), _handle(NULL), _filename(filename), _ok(false)
{
    if(!filename.empty())
    {
        krb5_error_code code = krb5_kt_resolve(_ctx, filename.c_str(), &_handle);
        _ok = (code == 0);
        if(!_ok)
            throw error(this, code);
    }
}
keytab::~keytab()
{
    if(_handle)
        krb5_kt_close(_ctx, _handle);
}

bool keytab::valid() const
{
    return _ok;
}

const std::string & keytab::get_filename() const
{
    return _filename;
}

bool keytab::list(const list_handler & handler)
{
    bool ret = false;
    if(_ok)
    {
        krb5_kt_cursor cursor = NULL;
        krb5_keytab_entry entry;
        krb5_error_code code;

        code = krb5_kt_start_seq_get (_ctx, _handle, &cursor);
        if(code)
            throw error(this, code);
        ret = (code == 0);
        while(!code)
        {
            code = krb5_kt_next_entry (_ctx, _handle, &entry, &cursor);
            if (code == 0)
            {
                keytab_entry e(_ctx, &entry);
                handler(e);
            }
        }

        if (code == KRB5_KT_END)
            code = 0;

        if(cursor)
            krb5_kt_end_seq_get (_ctx, _handle, &cursor);

    }
    return ret;
}

bool keytab::update(const keytab & source)
{
    bool ret = false;
    if(source._ok)
    {
        krb5_kt_cursor cursor = NULL;
        krb5_keytab_entry entry;
        krb5_error_code code;
        code = krb5_kt_start_seq_get (source._ctx, source._handle, &cursor);
        ret = (code == 0);
        while(!code)
        {
            code = krb5_kt_next_entry (source._ctx, source._handle, &entry, &cursor);
            if (code == 0)
            {
                updateEntry(&entry);

                // release all memory
                krb5_free_keytab_entry_contents(_ctx, &entry);
            }
        }

        if (code == KRB5_KT_END)
            code = 0;

        if(cursor)
            krb5_kt_end_seq_get (source._ctx, source._handle, &cursor);
    }
    return ret;
}

krb5_error_code keytab::updateEntry(krb5_keytab_entry * updatedEntry)
{
    krb5_kt_cursor cursor = NULL;
    krb5_keytab_entry entry;
    krb5_error_code code;
    bool add_princ = true;

    code = krb5_kt_start_seq_get (_ctx, _handle, &cursor);
    while(!code && add_princ)
    {
        code = krb5_kt_next_entry (_ctx, _handle, &entry, &cursor);
        if (code == 0)
        {
            if(krb5_principal_compare(_ctx, entry.principal, updatedEntry->principal) && entry.key.enctype == updatedEntry->key.enctype)
            {
                if(entry.vno > updatedEntry->vno)
                {
                    // newer key entry with higher kvno is already in the keytab
                    add_princ = false;
                }
                else if(entry.vno == updatedEntry->vno)
                {
                    // found same kvno, so check timestamp
                    if(entry.timestamp >= updatedEntry->timestamp)
                    {
                        // same kvno but a new (or same) timestamp already in keytab
                        add_princ = false;
                    }
                }
            }
            // release all memory
            krb5_free_keytab_entry_contents(_ctx, &entry);
        }
    }

    if (code == KRB5_KT_END)
        code = 0;
    if(cursor)
        krb5_kt_end_seq_get (_ctx, _handle, &cursor);
    if(add_princ)
        code = krb5_kt_add_entry(_ctx, _handle, updatedEntry);
    else
        code = 0;
    return code;
}
    } // namespace krb5
} // namespace arsoft
